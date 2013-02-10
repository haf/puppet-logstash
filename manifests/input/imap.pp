# == Define: logstash::input::imap
#
#   Read mail from IMAP servers  Periodically scans INBOX and moves any
#   read messages to the trash.
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
# [*check_interval*]
#   Value type is number
#   Default value: 300
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
# [*delete*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*fetch_count*]
#   Value type is number
#   Default value: 50
#   This variable is optional
#
# [*host*]
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*lowercase_headers*]
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*password*]
#   Value type is password
#   Default value: None
#   This variable is required
#
# [*port*]
#   Value type is number
#   Default value: None
#   This variable is optional
#
# [*secure*]
#   Value type is boolean
#   Default value: true
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
#   Value type is string
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
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.2.2.dev/inputs/imap
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::imap (
  $host,
  $user,
  $password,
  $lowercase_headers = '',
  $debug             = '',
  $delete            = '',
  $fetch_count       = '',
  $add_field         = '',
  $codec             = '',
  $check_interval    = '',
  $port              = '',
  $secure            = '',
  $tags              = '',
  $type              = '',
  $instances         = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_imap_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/imap/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_imap_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/imap/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($secure != '') {
    validate_bool($secure)
    $opt_secure = "  secure => ${secure}\n"
  }

  if ($delete != '') {
    validate_bool($delete)
    $opt_delete = "  delete => ${delete}\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($lowercase_headers != '') {
    validate_bool($lowercase_headers)
    $opt_lowercase_headers = "  lowercase_headers => ${lowercase_headers}\n"
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

  if ($fetch_count != '') {
    if ! is_numeric($fetch_count) {
      fail("\"${fetch_count}\" is not a valid fetch_count parameter value")
    } else {
      $opt_fetch_count = "  fetch_count => ${fetch_count}\n"
    }
  }

  if ($check_interval != '') {
    if ! is_numeric($check_interval) {
      fail("\"${check_interval}\" is not a valid check_interval parameter value")
    } else {
      $opt_check_interval = "  check_interval => ${check_interval}\n"
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

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n imap {\n${opt_add_field}${opt_check_interval}${opt_codec}${opt_debug}${opt_delete}${opt_fetch_count}${opt_host}${opt_lowercase_headers}${opt_password}${opt_port}${opt_secure}${opt_tags}${opt_type}${opt_user} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
