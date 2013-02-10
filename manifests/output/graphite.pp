# == Define: logstash::output::graphite
#
#   This output allows you to pull metrics from your logs and ship them to
#   graphite. Graphite is an open source tool for storing and graphing
#   metrics.  An example use case: At loggly, some of our applications
#   emit aggregated stats in the logs every 10 seconds. Using the grok
#   filter and this output, I can capture the metric values from the logs
#   and emit them to graphite.
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
#   Enable debug output
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*exclude_metrics*]
#   Exclude regex matched metric names, by default exclude unresolved
#   %{field} strings
#   Value type is array
#   Default value: ["%{[^}]+}"]
#   This variable is optional
#
# [*fields_are_metrics*]
#   Indicate that the event @fields should be treated as metrics and will
#   be sent as is to graphite
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   The address of the graphite server.
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*include_metrics*]
#   Include only regex matched metric names
#   Value type is array
#   Default value: [".*"]
#   This variable is optional
#
# [*metrics*]
#   The metric(s) to use. This supports dynamic strings like %{host} for
#   metric names and also for values. This is a hash field with key of the
#   metric name, value of the metric value. Example:  [ "%{host}/uptime",
#   "%{uptime_1m}" ]   The value will be coerced to a floating point
#   value. Values which cannot be coerced will zero (0)
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*metrics_format*]
#   Defines format of the metric string. The placeholder '*' will be
#   replaced with the name of the actual metric.  metrics_format =&gt;
#   "foo.bar.*.sum"   NOTE: If no metrics_format is defined the name of
#   the metric will be used as fallback.
#   Value type is string
#   Default value: "*"
#   This variable is optional
#
# [*port*]
#   The port to connect on your graphite server.
#   Value type is number
#   Default value: 2003
#   This variable is optional
#
# [*reconnect_interval*]
#   Interval between reconnect attempts to carboon
#   Value type is number
#   Default value: 2
#   This variable is optional
#
# [*resend_on_failure*]
#   Should metrics be resend on failure?
#   Value type is boolean
#   Default value: false
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
#  http://logstash.net/docs/1.2.2.dev/outputs/graphite
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::graphite (
  $codec              = '',
  $debug              = '',
  $exclude_metrics    = '',
  $fields_are_metrics = '',
  $host               = '',
  $include_metrics    = '',
  $metrics            = '',
  $metrics_format     = '',
  $port               = '',
  $reconnect_interval = '',
  $resend_on_failure  = '',
  $instances          = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_graphite_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/graphite/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_graphite_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/graphite/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($include_metrics != '') {
    validate_array($include_metrics)
    $arr_include_metrics = join($include_metrics, '\', \'')
    $opt_include_metrics = "  include_metrics => ['${arr_include_metrics}']\n"
  }

  if ($exclude_metrics != '') {
    validate_array($exclude_metrics)
    $arr_exclude_metrics = join($exclude_metrics, '\', \'')
    $opt_exclude_metrics = "  exclude_metrics => ['${arr_exclude_metrics}']\n"
  }

  if ($fields_are_metrics != '') {
    validate_bool($fields_are_metrics)
    $opt_fields_are_metrics = "  fields_are_metrics => ${fields_are_metrics}\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($resend_on_failure != '') {
    validate_bool($resend_on_failure)
    $opt_resend_on_failure = "  resend_on_failure => ${resend_on_failure}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($metrics != '') {
    validate_hash($metrics)
    $var_metrics = $metrics
    $arr_metrics = inline_template('<%= "["+@var_metrics.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_metrics = "  metrics => ${arr_metrics}\n"
  }

  if ($reconnect_interval != '') {
    if ! is_numeric($reconnect_interval) {
      fail("\"${reconnect_interval}\" is not a valid reconnect_interval parameter value")
    } else {
      $opt_reconnect_interval = "  reconnect_interval => ${reconnect_interval}\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($metrics_format != '') {
    validate_string($metrics_format)
    $opt_metrics_format = "  metrics_format => \"${metrics_format}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n graphite {\n${opt_codec}${opt_debug}${opt_exclude_metrics}${opt_fields_are_metrics}${opt_host}${opt_include_metrics}${opt_metrics}${opt_metrics_format}${opt_port}${opt_reconnect_interval}${opt_resend_on_failure} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
