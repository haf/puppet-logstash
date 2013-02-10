# == Define: logstash::input::irc
#
#   Read events from an IRC Server.
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
# [*channels*]
#   Channels to join and read messages from.  These should be full channel
#   names including the '#' symbol, such as "#logstash".
#   Value type is array
#   Default value: None
#   This variable is required
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
# [*host*]
#   Host of the IRC Server to connect to.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*nick*]
#   IRC Nickname
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*password*]
#   IRC Server password
#   Value type is password
#   Default value: None
#   This variable is optional
#
# [*port*]
#   Port for the IRC Server
#   Value type is number
#   Default value: 6667
#   This variable is optional
#
# [*real*]
#   IRC Real name
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*secure*]
#   Set this to true to enable SSL.
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
#   IRC Username
#   Value type is string
#   Default value: "logstash"
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
#  http://logstash.net/docs/1.2.2.dev/inputs/irc
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::irc (
  $channels,
  $host,
  $nick           = '',
  $codec          = '',
  $debug          = '',
  $add_field      = '',
  $password       = '',
  $port           = '',
  $real           = '',
  $secure         = '',
  $tags           = '',
  $type           = '',
  $user           = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_irc_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/irc/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_irc_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/irc/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($channels != '') {
    validate_array($channels)
    $arr_channels = join($channels, '\', \'')
    $opt_channels = "  channels => ['${arr_channels}']\n"
  }

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($secure != '') {
    validate_bool($secure)
    $opt_secure = "  secure => ${secure}\n"
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

  if ($real != '') {
    validate_string($real)
    $opt_real = "  real => \"${real}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($nick != '') {
    validate_string($nick)
    $opt_nick = "  nick => \"${nick}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n irc {\n${opt_add_field}${opt_channels}${opt_codec}${opt_debug}${opt_host}${opt_nick}${opt_password}${opt_port}${opt_real}${opt_secure}${opt_tags}${opt_type}${opt_user} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
