# == Define: logstash::output::opentsdb
#
#   This output allows you to pull metrics from your logs and ship them to
#   opentsdb. Opentsdb is an open source tool for storing and graphing
#   metrics.
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
#   Enable debugging. Tries to pretty-print the entire event object.
#   Value type is boolean
#   Default value: None
#   This variable is optional
#
# [*host*]
#   The address of the opentsdb server.
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*metrics*]
#   The metric(s) to use. This supports dynamic strings like
#   %{source_host} for metric names and also for values. This is an array
#   field with key of the metric name, value of the metric value, and
#   multiple tag,values . Example:  [   "%{host}/uptime",   %{uptime_1m} "
#   ,   "hostname" ,   "%{host}   "anotherhostname" ,   "%{host} ]   The
#   value will be coerced to a floating point value. Values which cannot
#   be coerced will zero (0)
#   Value type is array
#   Default value: None
#   This variable is required
#
# [*port*]
#   The port to connect on your graphite server.
#   Value type is number
#   Default value: 4242
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
#  http://logstash.net/docs/1.2.2.dev/outputs/opentsdb
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::opentsdb (
  $metrics,
  $codec        = '',
  $host         = '',
  $debug        = '',
  $port         = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_opentsdb_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/opentsdb/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_opentsdb_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/opentsdb/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($metrics != '') {
    validate_array($metrics)
    $arr_metrics = join($metrics, '\', \'')
    $opt_metrics = "  metrics => ['${arr_metrics}']\n"
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

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n opentsdb {\n${opt_codec}${opt_debug}${opt_host}${opt_metrics}${opt_port} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
