# == Define: logstash::output::datadog_metrics
#
#   This output lets you send metrics to DataDogHQ based on Logstash
#   events. Default queue_size and timeframe are low in order to provide
#   near realtime alerting. If you do not use Datadog for alerting,
#   consider raising these thresholds.
#
#
# === Parameters
#
# [*api_key*]
#   Your DatadogHQ API key. https://app.datadoghq.com/account/settings#api
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*dd_tags*]
#   Set any custom tags for this event, default are the Logstash tags if
#   any.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*device*]
#   The name of the device that produced the metric.
#   Value type is string
#   Default value: "%{metric_device}"
#   This variable is optional
#
# [*host*]
#   The name of the host that produced the metric.
#   Value type is string
#   Default value: "%{host}"
#   This variable is optional
#
# [*metric_name*]
#   The name of the time series.
#   Value type is string
#   Default value: "%{metric_name}"
#   This variable is optional
#
# [*metric_type*]
#   The type of the metric.
#   Value can be any of: "gauge", "counter"
#   Default value: "%{metric_type}"
#   This variable is optional
#
# [*metric_value*]
#   The value.
#   Value type is String
#   Default value: "%{metric_value}"
#   This variable is optional
#
# [*queue_size*]
#   How many events to queue before flushing to Datadog prior to schedule
#   set in @timeframe
#   Value type is number
#   Default value: 10
#   This variable is optional
#
# [*timeframe*]
#   How often (in seconds) to flush queued events to Datadog
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
#  http://logstash.net/docs/1.2.2.dev/outputs/datadog_metrics
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::datadog_metrics (
  $api_key,
  $metric_type  = '',
  $dd_tags      = '',
  $device       = '',
  $host         = '',
  $metric_name  = '',
  $codec        = '',
  $metric_value = '',
  $queue_size   = '',
  $timeframe    = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_datadog_metrics_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/datadog_metrics/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_datadog_metrics_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/datadog_metrics/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($dd_tags != '') {
    validate_array($dd_tags)
    $arr_dd_tags = join($dd_tags, '\', \'')
    $opt_dd_tags = "  dd_tags => ['${arr_dd_tags}']\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($timeframe != '') {
    if ! is_numeric($timeframe) {
      fail("\"${timeframe}\" is not a valid timeframe parameter value")
    } else {
      $opt_timeframe = "  timeframe => ${timeframe}\n"
    }
  }

  if ($queue_size != '') {
    if ! is_numeric($queue_size) {
      fail("\"${queue_size}\" is not a valid queue_size parameter value")
    } else {
      $opt_queue_size = "  queue_size => ${queue_size}\n"
    }
  }

  if ($metric_value != '') {
    $opt_metric_value = "  metric_value => \"${metric_value}\"\n"
  }

  if ($metric_type != '') {
    if ! ($metric_type in ['gauge', 'counter']) {
      fail("\"${metric_type}\" is not a valid metric_type parameter value")
    } else {
      $opt_metric_type = "  metric_type => \"${metric_type}\"\n"
    }
  }

  if ($metric_name != '') {
    validate_string($metric_name)
    $opt_metric_name = "  metric_name => \"${metric_name}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($device != '') {
    validate_string($device)
    $opt_device = "  device => \"${device}\"\n"
  }

  if ($api_key != '') {
    validate_string($api_key)
    $opt_api_key = "  api_key => \"${api_key}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n datadog_metrics {\n${opt_api_key}${opt_codec}${opt_dd_tags}${opt_device}${opt_host}${opt_metric_name}${opt_metric_type}${opt_metric_value}${opt_queue_size}${opt_timeframe} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
