# == Define: logstash::input::tcp
#
#   Read events over a TCP socket.  Like stdin and file inputs, each event
#   is assumed to be one line of text.  Can either accept connections from
#   clients or connect to a server, depending on mode.
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
# [*data_timeout*]
#   The 'read' timeout in seconds. If a particular tcp connection is idle
#   for more than this timeout period, we will assume it is dead and close
#   it.  If you never want to timeout, use -1.
#   Value type is number
#   Default value: -1
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   When mode is server, the address to listen on. When mode is client,
#   the address to connect to.
#   Value type is string
#   Default value: "0.0.0.0"
#   This variable is optional
#
# [*mode*]
#   Mode to operate in. server listens for client connections, client
#   connects to a server.
#   Value can be any of: "server", "client"
#   Default value: "server"
#   This variable is optional
#
# [*port*]
#   When mode is server, the port to listen on. When mode is client, the
#   port to connect to.
#   Value type is number
#   Default value: None
#   This variable is required
#
# [*ssl_cacert*]
#   ssl CA certificate, chainfile or CA path The system CA path is
#   automatically included
#   Value type is path
#   Default value: None
#   This variable is optional
#
# [*ssl_cert*]
#   ssl certificate
#   Value type is path
#   Default value: None
#   This variable is optional
#
# [*ssl_enable*]
#   Enable ssl (must be set for other ssl_ options to take effect)
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*ssl_key*]
#   ssl key
#   Value type is path
#   Default value: None
#   This variable is optional
#
# [*ssl_key_passphrase*]
#   ssl key passphrase
#   Value type is password
#   Default value: nil
#   This variable is optional
#
# [*ssl_verify*]
#   Verify the identity of the other end of the ssl connection against the
#   CA For input, sets the @field.sslsubject to that of the client
#   certificate
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
#  http://logstash.net/docs/1.2.2.dev/inputs/tcp
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::tcp (
  $port,
  $add_field          = '',
  $codec              = '',
  $data_timeout       = '',
  $debug              = '',
  $host               = '',
  $mode               = '',
  $ssl_cacert         = '',
  $ssl_cert           = '',
  $ssl_enable         = '',
  $ssl_key            = '',
  $ssl_key_passphrase = '',
  $ssl_verify         = '',
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
    $conffiles    = suffix($confdirstart, "/config/input_tcp_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/tcp/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_tcp_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/tcp/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($ssl_verify != '') {
    validate_bool($ssl_verify)
    $opt_ssl_verify = "  ssl_verify => ${ssl_verify}\n"
  }

  if ($ssl_enable != '') {
    validate_bool($ssl_enable)
    $opt_ssl_enable = "  ssl_enable => ${ssl_enable}\n"
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

  if ($data_timeout != '') {
    if ! is_numeric($data_timeout) {
      fail("\"${data_timeout}\" is not a valid data_timeout parameter value")
    } else {
      $opt_data_timeout = "  data_timeout => ${data_timeout}\n"
    }
  }

  if ($mode != '') {
    if ! ($mode in ['server', 'client']) {
      fail("\"${mode}\" is not a valid mode parameter value")
    } else {
      $opt_mode = "  mode => \"${mode}\"\n"
    }
  }

  if ($ssl_key_passphrase != '') {
    validate_string($ssl_key_passphrase)
    $opt_ssl_key_passphrase = "  ssl_key_passphrase => \"${ssl_key_passphrase}\"\n"
  }

  if ($ssl_cacert != '') {
    if $ssl_cacert =~ /^puppet\:\/\// {

      validate_re($ssl_cacert, '\Apuppet:\/\/')

      $filenameArray_ssl_cacert = split($ssl_cacert, '/')
      $basefilename_ssl_cacert = $filenameArray_ssl_cacert[-1]

      $opt_ssl_cacert = "  ssl_cacert => \"${filesdir}/${basefilename_ssl_cacert}\"\n"

      file { "${filesdir}/${basefilename_ssl_cacert}":
        source  => $ssl_cacert,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_ssl_cacert = "  ssl_cacert => \"${ssl_cacert}\"\n"
    }
  }

  if ($ssl_cert != '') {
    if $ssl_cert =~ /^puppet\:\/\// {

      validate_re($ssl_cert, '\Apuppet:\/\/')

      $filenameArray_ssl_cert = split($ssl_cert, '/')
      $basefilename_ssl_cert = $filenameArray_ssl_cert[-1]

      $opt_ssl_cert = "  ssl_cert => \"${filesdir}/${basefilename_ssl_cert}\"\n"

      file { "${filesdir}/${basefilename_ssl_cert}":
        source  => $ssl_cert,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_ssl_cert = "  ssl_cert => \"${ssl_cert}\"\n"
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

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }


  #### Create the directory where we place the files
  exec { "create_files_dir_input_tcp_${name}":
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
    require => Exec["create_files_dir_input_tcp_${name}"],
    notify  => Service[$services]
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n tcp {\n${opt_add_field}${opt_codec}${opt_data_timeout}${opt_debug}${opt_host}${opt_mode}${opt_port}${opt_ssl_cacert}${opt_ssl_cert}${opt_ssl_enable}${opt_ssl_key}${opt_ssl_key_passphrase}${opt_ssl_verify}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
