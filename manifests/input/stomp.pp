# == Define: logstash::input::stomp
#
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
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*debug*]
#   Enable debugging output?
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*destination*]
#   The destination to read events from.  Example: "/topic/logstash"
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*host*]
#   The address of the STOMP server.
#   Value type is string
#   Default value: "localhost"
#   This variable is required
#
# [*password*]
#   The password to authenticate with.
#   Value type is password
#   Default value: ""
#   This variable is optional
#
# [*port*]
#   The port to connet to on your STOMP server.
#   Value type is number
#   Default value: 61613
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
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
#   The username to authenticate with.
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*vhost*]
#   The vhost to use
#   Value type is string
#   Default value: nil
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
#  http://logstash.net/docs/1.2.2.dev/inputs/stomp
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::stomp (
  $destination,
  $host,
  $debug          = '',
  $add_field      = '',
  $codec          = '',
  $password       = '',
  $port           = '',
  $tags           = '',
  $type           = '',
  $user           = '',
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
    $conffiles    = suffix($confdirstart, "/config/input_stomp_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/stomp/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_stomp_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/stomp/${name}"

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

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($destination != '') {
    validate_string($destination)
    $opt_destination = "  destination => \"${destination}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($vhost != '') {
    validate_string($vhost)
    $opt_vhost = "  vhost => \"${vhost}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n stomp {\n${opt_add_field}${opt_codec}${opt_debug}${opt_destination}${opt_host}${opt_password}${opt_port}${opt_tags}${opt_type}${opt_user}${opt_vhost} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
