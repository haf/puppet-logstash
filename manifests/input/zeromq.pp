# == Define: logstash::input::zeromq
#
#   Read events over a 0MQ SUB socket.  You need to have the 0mq 2.1.x
#   library installed to be able to use this input plugin.  The default
#   settings will create a subscriber binding to tcp://127.0.0.1:2120
#   waiting for connecting publishers.
#
#
# === Parameters
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*address*]
#   0mq socket address to connect or bind Please note that inproc:// will
#   not work with logstash as each we use a context per thread. By
#   default, inputs bind/listen and outputs connect
#   Value type is array
#   Default value: ["tcp://*:2120"]
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*mode*]
#   mode server mode binds/listens client mode connects
#   Value can be any of: "server", "client"
#   Default value: "server"
#   This variable is optional
#
# [*sender*]
#   sender overrides the sender to set the source of the event default is
#   "zmq+topology://type/"
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*sockopt*]
#   0mq socket options This exposes zmq_setsockopt for advanced tuning see
#   http://api.zeromq.org/2-1:zmq-setsockopt for details  This is where
#   you would set values like: ZMQ::HWM - high water mark ZMQ::IDENTITY -
#   named queues ZMQ::SWAP_SIZE - space for disk overflow  example:
#   sockopt =&gt; ["ZMQ::HWM", 50, "ZMQ::IDENTITY", "mynamedqueue"]
#   Value type is hash
#   Default value: None
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*topic*]
#   0mq topic This is used for the 'pubsub' topology only On inputs, this
#   allows you to filter messages by topic On outputs, this allows you to
#   tag a message for routing NOTE: ZeroMQ does subscriber side filtering.
#   NOTE: All topics have an implicit wildcard at the end You can specify
#   multiple topics here
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*topology*]
#   0mq topology The default logstash topologies work as follows: *
#   pushpull - inputs are pull, outputs are push * pubsub - inputs are
#   subscribers, outputs are publishers * pair - inputs are clients,
#   inputs are servers  If the predefined topology flows don't work for
#   you, you can change the 'mode' setting TODO (lusis) add req/rep MAYBE
#   TODO (lusis) add router/dealer
#   Value can be any of: "pushpull", "pubsub", "pair"
#   Default value: None
#   This variable is required
#
# [*type*]
#   Add a 'type' field to all events handled by this input.  Types are
#   used mainly for filter activation.  If you create an input with type
#   "foobar", then only filters which also have type "foobar" will act on
#   them.  The type is also stored as part of the event itself, so you can
#   also use the type to search for in the web interface.  If you try to
#   set a type on an event that already has one (for example when you send
#   an event from a shipper to an indexer) then a new input will not
#   override the existing type. A type set at the shipper stays with that
#   event for its life even when sent to another LogStash server.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*instances*]
#   Array of instance names to which this define is.
#   Value type is array
#   Default value: [ 'array' ]
#   This variable is optional
#
# === Extra information
#
#  This define is created based on LogStash version 1.2.2.dev
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.2.2.dev/inputs/zeromq
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::zeromq (
  $topology,
  $mode           = '',
  $codec          = '',
  $debug          = '',
  $address        = '',
  $sender         = '',
  $sockopt        = '',
  $tags           = '',
  $topic          = '',
  $add_field      = '',
  $type           = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_zeromq_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/zeromq/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_zeromq_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/zeromq/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($address != '') {
    validate_array($address)
    $arr_address = join($address, '\', \'')
    $opt_address = "  address => ['${arr_address}']\n"
  }

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($topic != '') {
    validate_array($topic)
    $arr_topic = join($topic, '\', \'')
    $opt_topic = "  topic => ['${arr_topic}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($sockopt != '') {
    validate_hash($sockopt)
    $var_sockopt = $sockopt
    $arr_sockopt = inline_template('<%= "["+@var_sockopt.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_sockopt = "  sockopt => ${arr_sockopt}\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($mode != '') {
    if ! ($mode in ['server', 'client']) {
      fail("\"${mode}\" is not a valid mode parameter value")
    } else {
      $opt_mode = "  mode => \"${mode}\"\n"
    }
  }

  if ($topology != '') {
    if ! ($topology in ['pushpull', 'pubsub', 'pair']) {
      fail("\"${topology}\" is not a valid topology parameter value")
    } else {
      $opt_topology = "  topology => \"${topology}\"\n"
    }
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($sender != '') {
    validate_string($sender)
    $opt_sender = "  sender => \"${sender}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n zeromq {\n${opt_add_field}${opt_address}${opt_codec}${opt_debug}${opt_mode}${opt_sender}${opt_sockopt}${opt_tags}${opt_topic}${opt_topology}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
