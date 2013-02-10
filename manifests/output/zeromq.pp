# == Define: logstash::output::zeromq
#
#   Write events to a 0MQ PUB socket.  You need to have the 0mq 2.1.x
#   library installed to be able to use this output plugin.  The default
#   settings will create a publisher connecting to a subscriber bound to
#   tcp://127.0.0.1:2120
#
#
# === Parameters
#
# [*address*]
#   0mq socket address to connect or bind. Please note that inproc:// will
#   not work with logstashi. For each we use a context per thread. By
#   default, inputs bind/listen and outputs connect.
#   Value type is array
#   Default value: ["tcp://127.0.0.1:2120"]
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*mode*]
#   Server mode binds/listens. Client mode connects.
#   Value can be any of: "server", "client"
#   Default value: "client"
#   This variable is optional
#
# [*sockopt*]
#   This exposes zmq_setsockopt for advanced tuning. See
#   http://api.zeromq.org/2-1:zmq-setsockopt for details.  This is where
#   you would set values like:  ZMQ::HWM - high water mark ZMQ::IDENTITY -
#   named queues ZMQ::SWAP_SIZE - space for disk overflow Example: sockopt
#   =&gt; ["ZMQ::HWM", 50, "ZMQ::IDENTITY", "mynamedqueue"]
#   Value type is hash
#   Default value: None
#   This variable is optional
#
# [*topic*]
#   This is used for the 'pubsub' topology only. On inputs, this allows
#   you to filter messages by topic. On outputs, this allows you to tag a
#   message for routing. NOTE: ZeroMQ does subscriber-side filtering NOTE:
#   Topic is evaluated with event.sprintf so macros are valid here.
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*topology*]
#   The default logstash topologies work as follows:  pushpull - inputs
#   are pull, outputs are push pubsub - inputs are subscribers, outputs
#   are publishers pair - inputs are clients, inputs are servers If the
#   predefined topology flows don't work for you, you can change the
#   'mode' setting TODO (lusis) add req/rep MAYBE TODO (lusis) add
#   router/dealer
#   Value can be any of: "pushpull", "pubsub", "pair"
#   Default value: None
#   This variable is required
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
#  Extra information about this output can be found at:
#  http://logstash.net/docs/1.2.2.dev/outputs/zeromq
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::zeromq (
  $topology,
  $mode         = '',
  $sockopt      = '',
  $codec        = '',
  $topic        = '',
  $address      = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_zeromq_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/zeromq/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_zeromq_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/zeromq/${name}"

  }

  #### Validate parameters
  if ($address != '') {
    validate_array($address)
    $arr_address = join($address, '\', \'')
    $opt_address = "  address => ['${arr_address}']\n"
  }


  validate_array($instances)

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

  if ($topology != '') {
    if ! ($topology in ['pushpull', 'pubsub', 'pair']) {
      fail("\"${topology}\" is not a valid topology parameter value")
    } else {
      $opt_topology = "  topology => \"${topology}\"\n"
    }
  }

  if ($mode != '') {
    if ! ($mode in ['server', 'client']) {
      fail("\"${mode}\" is not a valid mode parameter value")
    } else {
      $opt_mode = "  mode => \"${mode}\"\n"
    }
  }

  if ($topic != '') {
    validate_string($topic)
    $opt_topic = "  topic => \"${topic}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n zeromq {\n${opt_address}${opt_codec}${opt_mode}${opt_sockopt}${opt_topic}${opt_topology} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
