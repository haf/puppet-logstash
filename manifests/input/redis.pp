# == Define: logstash::input::redis
#
#   Read events from a redis. Supports both redis channels and also redis
#   lists (using BLPOP)  For more information about redis, see
#   http://redis.io/  batch_count note  If you use the 'batch_count'
#   setting, you must use a redis version 2.6.0 or newer. Anything older
#   does not support the operations used by batching.
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
# [*batch_count*]
#   How many events to return from redis using EVAL
#   Value type is number
#   Default value: 1
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*data_type*]
#   Either list or channel.  If redis_type is list, then we will BLPOP the
#   key.  If redis_type is channel, then we will SUBSCRIBE to the key. If
#   redis_type is pattern_channel, then we will PSUBSCRIBE to the key.
#   TODO: change required to true
#   Value can be any of: "list", "channel", "pattern_channel"
#   Default value: None
#   This variable is optional
#
# [*db*]
#   The redis database number.
#   Value type is number
#   Default value: 0
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   The hostname of your redis server.
#   Value type is string
#   Default value: "127.0.0.1"
#   This variable is optional
#
# [*key*]
#   The name of a redis list or channel. TODO: change required to true
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*password*]
#   Password to authenticate with. There is no authentication by default.
#   Value type is password
#   Default value: None
#   This variable is optional
#
# [*port*]
#   The port to connect on.
#   Value type is number
#   Default value: 6379
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
#   Set this to the number of threads you want this input to spawn. This
#   is the same as declaring the input multiple times
#   Value type is number
#   Default value: 1
#   This variable is optional
#
# [*timeout*]
#   Initial connection timeout in seconds.
#   Value type is number
#   Default value: 5
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
#  http://logstash.net/docs/1.2.2.dev/inputs/redis
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::redis (
  $add_field      = '',
  $batch_count    = '',
  $codec          = '',
  $data_type      = '',
  $db             = '',
  $debug          = '',
  $host           = '',
  $key            = '',
  $password       = '',
  $port           = '',
  $tags           = '',
  $threads        = '',
  $timeout        = '',
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
    $conffiles    = suffix($confdirstart, "/config/input_redis_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/redis/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_redis_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/redis/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
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

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($db != '') {
    if ! is_numeric($db) {
      fail("\"${db}\" is not a valid db parameter value")
    } else {
      $opt_db = "  db => ${db}\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($batch_count != '') {
    if ! is_numeric($batch_count) {
      fail("\"${batch_count}\" is not a valid batch_count parameter value")
    } else {
      $opt_batch_count = "  batch_count => ${batch_count}\n"
    }
  }

  if ($timeout != '') {
    if ! is_numeric($timeout) {
      fail("\"${timeout}\" is not a valid timeout parameter value")
    } else {
      $opt_timeout = "  timeout => ${timeout}\n"
    }
  }

  if ($threads != '') {
    if ! is_numeric($threads) {
      fail("\"${threads}\" is not a valid threads parameter value")
    } else {
      $opt_threads = "  threads => ${threads}\n"
    }
  }

  if ($data_type != '') {
    if ! ($data_type in ['list', 'channel', 'pattern_channel']) {
      fail("\"${data_type}\" is not a valid data_type parameter value")
    } else {
      $opt_data_type = "  data_type => \"${data_type}\"\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($key != '') {
    validate_string($key)
    $opt_key = "  key => \"${key}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n redis {\n${opt_add_field}${opt_batch_count}${opt_codec}${opt_data_type}${opt_db}${opt_debug}${opt_host}${opt_key}${opt_password}${opt_port}${opt_tags}${opt_threads}${opt_timeout}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
