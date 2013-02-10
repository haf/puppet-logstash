# == Define: logstash::input::zenoss
#
#
#
# === Parameters
#
# [*ack*]
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*arguments*]
#   Value type is array
#   Default value: {}
#   This variable is optional
#
# [*auto_delete*]
#   Value type is boolean
#   Default value: true
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
# [*durable*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*exchange*]
#   The name of the exchange to bind the queue. This is analogous to the
#   'rabbitmq output' config 'name'
#   Value type is string
#   Default value: "zenoss.zenevents"
#   This variable is optional
#
# [*exclusive*]
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*host*]
#   Your rabbitmq server address
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*key*]
#   The routing key to use. This is only valid for direct or fanout
#   exchanges  Routing keys are ignored on topic exchanges. Wildcards are
#   not valid on direct exchanges.
#   Value type is string
#   Default value: "zenoss.zenevent.#"
#   This variable is optional
#
# [*passive*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*password*]
#   Your rabbitmq password
#   Value type is password
#   Default value: "zenoss"
#   This variable is optional
#
# [*port*]
#   Value type is number
#   Default value: 5672
#   This variable is optional
#
# [*prefetch_count*]
#   Value type is number
#   Default value: 256
#   This variable is optional
#
# [*queue*]
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*ssl*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*threads*]
#   Value type is number
#   Default value: 1
#   This variable is optional
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
# [*user*]
#   Your rabbitmq username
#   Value type is string
#   Default value: "zenoss"
#   This variable is optional
#
# [*verify_ssl*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*vhost*]
#   The vhost to use. If you don't know what this is, leave the default.
#   Value type is string
#   Default value: "/zenoss"
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
#  http://logstash.net/docs/1.2.2.dev/inputs/zenoss
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::zenoss (
  $ack            = '',
  $add_field      = '',
  $arguments      = '',
  $auto_delete    = '',
  $codec          = '',
  $debug          = '',
  $durable        = '',
  $exchange       = '',
  $exclusive      = '',
  $host           = '',
  $key            = '',
  $passive        = '',
  $password       = '',
  $port           = '',
  $prefetch_count = '',
  $queue          = '',
  $ssl            = '',
  $tags           = '',
  $threads        = '',
  $type           = '',
  $user           = '',
  $verify_ssl     = '',
  $vhost          = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_zenoss_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/zenoss/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_zenoss_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/zenoss/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($arguments != '') {
    validate_array($arguments)
    $arr_arguments = join($arguments, '\', \'')
    $opt_arguments = "  arguments => ['${arr_arguments}']\n"
  }

  if ($ssl != '') {
    validate_bool($ssl)
    $opt_ssl = "  ssl => ${ssl}\n"
  }

  if ($verify_ssl != '') {
    validate_bool($verify_ssl)
    $opt_verify_ssl = "  verify_ssl => ${verify_ssl}\n"
  }

  if ($auto_delete != '') {
    validate_bool($auto_delete)
    $opt_auto_delete = "  auto_delete => ${auto_delete}\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($durable != '') {
    validate_bool($durable)
    $opt_durable = "  durable => ${durable}\n"
  }

  if ($passive != '') {
    validate_bool($passive)
    $opt_passive = "  passive => ${passive}\n"
  }

  if ($exclusive != '') {
    validate_bool($exclusive)
    $opt_exclusive = "  exclusive => ${exclusive}\n"
  }

  if ($ack != '') {
    validate_bool($ack)
    $opt_ack = "  ack => ${ack}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($threads != '') {
    if ! is_numeric($threads) {
      fail("\"${threads}\" is not a valid threads parameter value")
    } else {
      $opt_threads = "  threads => ${threads}\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($prefetch_count != '') {
    if ! is_numeric($prefetch_count) {
      fail("\"${prefetch_count}\" is not a valid prefetch_count parameter value")
    } else {
      $opt_prefetch_count = "  prefetch_count => ${prefetch_count}\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($queue != '') {
    validate_string($queue)
    $opt_queue = "  queue => \"${queue}\"\n"
  }

  if ($exchange != '') {
    validate_string($exchange)
    $opt_exchange = "  exchange => \"${exchange}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($key != '') {
    validate_string($key)
    $opt_key = "  key => \"${key}\"\n"
  }

  if ($vhost != '') {
    validate_string($vhost)
    $opt_vhost = "  vhost => \"${vhost}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n zenoss {\n${opt_ack}${opt_add_field}${opt_arguments}${opt_auto_delete}${opt_codec}${opt_debug}${opt_durable}${opt_exchange}${opt_exclusive}${opt_host}${opt_key}${opt_passive}${opt_password}${opt_port}${opt_prefetch_count}${opt_queue}${opt_ssl}${opt_tags}${opt_threads}${opt_type}${opt_user}${opt_verify_ssl}${opt_vhost} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
