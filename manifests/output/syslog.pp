# == Define: logstash::output::syslog
#
#   Send events to a syslog server.  You can send messages compliant with
#   RFC3164 or RFC5424 UDP or TCP syslog transport is supported
#
#
# === Parameters
#
# [*appname*]
#   application name for syslog message
#   Value type is string
#   Default value: "LOGSTASH"
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*facility*]
#   facility label for syslog message
#   Value can be any of: "kernel", "user-level", "mail", "daemon",
#   "security/authorization", "syslogd", "line printer", "network news",
#   "uucp", "clock", "security/authorization", "ftp", "ntp", "log audit",
#   "log alert", "clock", "local0", "local1", "local2", "local3",
#   "local4", "local5", "local6", "local7"
#   Default value: None
#   This variable is required
#
# [*host*]
#   syslog server address to connect to
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*msgid*]
#   message id for syslog message
#   Value type is string
#   Default value: "-"
#   This variable is optional
#
# [*port*]
#   syslog server port to connect to
#   Value type is number
#   Default value: None
#   This variable is required
#
# [*procid*]
#   process id for syslog message
#   Value type is string
#   Default value: "-"
#   This variable is optional
#
# [*protocol*]
#   syslog server protocol. you can choose between udp and tcp
#   Value can be any of: "tcp", "udp"
#   Default value: "udp"
#   This variable is optional
#
# [*rfc*]
#   syslog message format: you can choose between rfc3164 or rfc5424
#   Value can be any of: "rfc3164", "rfc5424"
#   Default value: "rfc3164"
#   This variable is optional
#
# [*severity*]
#   severity label for syslog message
#   Value can be any of: "emergency", "alert", "critical", "error",
#   "warning", "notice", "informational", "debug"
#   Default value: None
#   This variable is required
#
# [*sourcehost*]
#   source host for syslog message
#   Value type is string
#   Default value: "%{host}"
#   This variable is optional
#
# [*timestamp*]
#   timestamp for syslog message
#   Value type is string
#   Default value: "%{@timestamp}"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/syslog
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::syslog (
  $facility,
  $severity,
  $port,
  $host,
  $protocol     = '',
  $msgid        = '',
  $procid       = '',
  $appname      = '',
  $rfc          = '',
  $codec        = '',
  $sourcehost   = '',
  $timestamp    = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_syslog_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/syslog/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_syslog_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/syslog/${name}"

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

  if ($severity != '') {
    if ! ($severity in ['emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'informational', 'debug']) {
      fail("\"${severity}\" is not a valid severity parameter value")
    } else {
      $opt_severity = "  severity => \"${severity}\"\n"
    }
  }

  if ($facility != '') {
    if ! ($facility in ['kernel', 'user-level', 'mail', 'daemon', 'security/authorization', 'syslogd', 'line printer', 'network news', 'uucp', 'clock', 'security/authorization', 'ftp', 'ntp', 'log audit', 'log alert', 'clock', 'local0', 'local1', 'local2', 'local3', 'local4', 'local5', 'local6', 'local7']) {
      fail("\"${facility}\" is not a valid facility parameter value")
    } else {
      $opt_facility = "  facility => \"${facility}\"\n"
    }
  }

  if ($rfc != '') {
    if ! ($rfc in ['rfc3164', 'rfc5424']) {
      fail("\"${rfc}\" is not a valid rfc parameter value")
    } else {
      $opt_rfc = "  rfc => \"${rfc}\"\n"
    }
  }

  if ($protocol != '') {
    if ! ($protocol in ['tcp', 'udp']) {
      fail("\"${protocol}\" is not a valid protocol parameter value")
    } else {
      $opt_protocol = "  protocol => \"${protocol}\"\n"
    }
  }

  if ($procid != '') {
    validate_string($procid)
    $opt_procid = "  procid => \"${procid}\"\n"
  }

  if ($msgid != '') {
    validate_string($msgid)
    $opt_msgid = "  msgid => \"${msgid}\"\n"
  }

  if ($sourcehost != '') {
    validate_string($sourcehost)
    $opt_sourcehost = "  sourcehost => \"${sourcehost}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($timestamp != '') {
    validate_string($timestamp)
    $opt_timestamp = "  timestamp => \"${timestamp}\"\n"
  }

  if ($appname != '') {
    validate_string($appname)
    $opt_appname = "  appname => \"${appname}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n syslog {\n${opt_appname}${opt_codec}${opt_facility}${opt_host}${opt_msgid}${opt_port}${opt_procid}${opt_protocol}${opt_rfc}${opt_severity}${opt_sourcehost}${opt_timestamp} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
