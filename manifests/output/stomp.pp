# == Define: logstash::output::stomp
#
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
# [*debug*]
#   Enable debugging output?
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*destination*]
#   The destination to read events from. Supports string expansion,
#   meaning %{foo} values will expand to the field value.  Example:
#   "/topic/logstash"
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*host*]
#   The address of the STOMP server.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*password*]
#   The password to authenticate with.
#   Value type is password
#   Default value: ""
#   This variable is optional
#
# [*port*]
#   The port to connect to on your STOMP server.
#   Value type is number
#   Default value: 61613
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
#  Extra information about this output can be found at:
#  http://logstash.net/docs/1.2.2.dev/outputs/stomp
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::stomp (
  $destination,
  $host,
  $port         = '',
  $debug        = '',
  $password     = '',
  $codec        = '',
  $user         = '',
  $vhost        = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_stomp_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/stomp/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_stomp_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/stomp/${name}"

  }

  #### Validate parameters

  validate_array($instances)

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

  if ($destination != '') {
    validate_string($destination)
    $opt_destination = "  destination => \"${destination}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
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
    content => "output {\n stomp {\n${opt_codec}${opt_debug}${opt_destination}${opt_host}${opt_password}${opt_port}${opt_user}${opt_vhost} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
