# == Define: logstash::input::lumberjack
#
#   Receive events using the lumberjack protocol.  This is mainly to
#   receive events shipped  with lumberjack,
#   http://github.com/jordansissel/lumberjack
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
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   the address to listen on.
#   Value type is string
#   Default value: "0.0.0.0"
#   This variable is optional
#
# [*port*]
#   the port to listen on.
#   Value type is number
#   Default value: None
#   This variable is required
#
# [*ssl_certificate*]
#   ssl certificate to use
#   Value type is path
#   Default value: None
#   This variable is required
#
# [*ssl_key*]
#   ssl key to use
#   Value type is path
#   Default value: None
#   This variable is required
#
# [*ssl_key_passphrase*]
#   ssl key passphrase to use
#   Value type is password
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
#  http://logstash.net/docs/1.2.2.dev/inputs/lumberjack
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::lumberjack (
  $port,
  $ssl_key,
  $ssl_certificate,
  $add_field          = '',
  $host               = '',
  $debug              = '',
  $codec              = '',
  $ssl_key_passphrase = '',
  $tags               = '',
  $type               = '',
  $instances          = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_lumberjack_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/lumberjack/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_lumberjack_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/lumberjack/${name}"

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

  if ($ssl_key_passphrase != '') {
    validate_string($ssl_key_passphrase)
    $opt_ssl_key_passphrase = "  ssl_key_passphrase => \"${ssl_key_passphrase}\"\n"
  }

  if ($ssl_certificate != '') {
    if $ssl_certificate =~ /^puppet\:\/\// {

      validate_re($ssl_certificate, '\Apuppet:\/\/')

      $filenameArray_ssl_certificate = split($ssl_certificate, '/')
      $basefilename_ssl_certificate = $filenameArray_ssl_certificate[-1]

      $opt_ssl_certificate = "  ssl_certificate => \"${filesdir}/${basefilename_ssl_certificate}\"\n"

      file { "${filesdir}/${basefilename_ssl_certificate}":
        source  => $ssl_certificate,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_ssl_certificate = "  ssl_certificate => \"${ssl_certificate}\"\n"
    }
  }

  if ($ssl_key != '') {
    if $ssl_key =~ /^puppet\:\/\// {

      validate_re($ssl_key, '\Apuppet:\/\/')

      $filenameArray_ssl_key = split($ssl_key, '/')
      $basefilename_ssl_key = $filenameArray_ssl_key[-1]

      $opt_ssl_key = "  ssl_key => \"${filesdir}/${basefilename_ssl_key}\"\n"

      file { "${filesdir}/${basefilename_ssl_key}":
        source  => $ssl_key,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_ssl_key = "  ssl_key => \"${ssl_key}\"\n"
    }
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }


  #### Create the directory where we place the files
  exec { "create_files_dir_input_lumberjack_${name}":
    cwd     => '/',
    path    => ['/usr/bin', '/bin'],
    command => "mkdir -p ${filesdir}",
    creates => $filesdir
  }

  #### Manage the files directory
  file { $filesdir:
    ensure  => directory,
    mode    => '0640',
    purge   => true,
    recurse => true,
    require => Exec["create_files_dir_input_lumberjack_${name}"],
    notify  => Service[$services]
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n lumberjack {\n${opt_add_field}${opt_codec}${opt_debug}${opt_host}${opt_port}${opt_ssl_certificate}${opt_ssl_key}${opt_ssl_key_passphrase}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
