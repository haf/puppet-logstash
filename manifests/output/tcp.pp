# == Define: logstash::output::tcp
#
#   Write events over a TCP socket.  Each event json is separated by a
#   newline.  Can either accept connections from clients or connect to a
#   server, depending on mode.
#
#
# === Parameters
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*host*]
#   When mode is server, the address to listen on. When mode is client,
#   the address to connect to.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*mode*]
#   Mode to operate in. server listens for client connections, client
#   connects to a server.
#   Value can be any of: "server", "client"
#   Default value: "client"
#   This variable is optional
#
# [*port*]
#   When mode is server, the port to listen on. When mode is client, the
#   port to connect to.
#   Value type is number
#   Default value: None
#   This variable is required
#
# [*reconnect_interval*]
#   When connect failed,retry interval in sec.
#   Value type is number
#   Default value: 10
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
#  Extra information about this output can be found at:
#  http://logstash.net/docs/1.2.2.dev/outputs/tcp
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::tcp (
  $port,
  $host,
  $codec              = '',
  $mode               = '',
  $reconnect_interval = '',
  $instances          = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_tcp_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/tcp/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_tcp_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/tcp/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($reconnect_interval != '') {
    if ! is_numeric($reconnect_interval) {
      fail("\"${reconnect_interval}\" is not a valid reconnect_interval parameter value")
    } else {
      $opt_reconnect_interval = "  reconnect_interval => ${reconnect_interval}\n"
    }
  }

  if ($mode != '') {
    if ! ($mode in ['server', 'client']) {
      fail("\"${mode}\" is not a valid mode parameter value")
    } else {
      $opt_mode = "  mode => \"${mode}\"\n"
    }
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n tcp {\n${opt_codec}${opt_host}${opt_mode}${opt_port}${opt_reconnect_interval} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
