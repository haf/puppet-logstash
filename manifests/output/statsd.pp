# == Define: logstash::output::statsd
#
#   statsd is a server for aggregating counters and other metrics to ship
#   to graphite.  The most basic coverage of this plugin is that the
#   'namespace', 'sender', and 'metric' names are combined into the full
#   metric path like so:  namespace.sender.metric   The general idea is
#   that you send statsd count or latency data and every few seconds it
#   will emit the aggregated values to graphite (aggregates like average,
#   max, stddev, etc)  You can learn about statsd here:
#   http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/
#   https://github.com/etsy/statsd A simple example usage of this is to
#   count HTTP hits by response code; to learn more about that, check out
#   the log metrics tutorial
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
# [*count*]
#   A count metric. metric_name =&gt; count as hash
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*debug*]
#   The final metric sent to statsd will look like the following (assuming
#   defaults) logstash.sender.file_name  Enable debugging output?
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*decrement*]
#   A decrement metric. metric names as array.
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*gauge*]
#   A gauge metric. metric_name =&gt; gauge as hash
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*host*]
#   The address of the Statsd server.
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*increment*]
#   An increment metric. metric names as array.
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*namespace*]
#   The statsd namespace to use for this metric
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*port*]
#   The port to connect to on your statsd server.
#   Value type is number
#   Default value: 8125
#   This variable is optional
#
# [*sample_rate*]
#   The sample rate for the metric
#   Value type is number
#   Default value: 1
#   This variable is optional
#
# [*sender*]
#   The name of the sender. Dots will be replaced with underscores
#   Value type is string
#   Default value: "%{host}"
#   This variable is optional
#
# [*set*]
#   A set metric. metric_name =&gt; string to append as hash
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*timing*]
#   A timing metric. metric_name =&gt; duration as hash
#   Value type is hash
#   Default value: {}
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
#  http://logstash.net/docs/1.2.2.dev/outputs/statsd
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::statsd (
  $codec        = '',
  $count        = '',
  $debug        = '',
  $decrement    = '',
  $gauge        = '',
  $host         = '',
  $increment    = '',
  $namespace    = '',
  $port         = '',
  $sample_rate  = '',
  $sender       = '',
  $set          = '',
  $timing       = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_statsd_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/statsd/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_statsd_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/statsd/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($increment != '') {
    validate_array($increment)
    $arr_increment = join($increment, '\', \'')
    $opt_increment = "  increment => ['${arr_increment}']\n"
  }

  if ($decrement != '') {
    validate_array($decrement)
    $arr_decrement = join($decrement, '\', \'')
    $opt_decrement = "  decrement => ['${arr_decrement}']\n"
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

  if ($set != '') {
    validate_hash($set)
    $var_set = $set
    $arr_set = inline_template('<%= "["+@var_set.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_set = "  set => ${arr_set}\n"
  }

  if ($gauge != '') {
    validate_hash($gauge)
    $var_gauge = $gauge
    $arr_gauge = inline_template('<%= "["+@var_gauge.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_gauge = "  gauge => ${arr_gauge}\n"
  }

  if ($timing != '') {
    validate_hash($timing)
    $var_timing = $timing
    $arr_timing = inline_template('<%= "["+@var_timing.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_timing = "  timing => ${arr_timing}\n"
  }

  if ($count != '') {
    validate_hash($count)
    $var_count = $count
    $arr_count = inline_template('<%= "["+@var_count.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_count = "  count => ${arr_count}\n"
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($sample_rate != '') {
    if ! is_numeric($sample_rate) {
      fail("\"${sample_rate}\" is not a valid sample_rate parameter value")
    } else {
      $opt_sample_rate = "  sample_rate => ${sample_rate}\n"
    }
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($sender != '') {
    validate_string($sender)
    $opt_sender = "  sender => \"${sender}\"\n"
  }

  if ($namespace != '') {
    validate_string($namespace)
    $opt_namespace = "  namespace => \"${namespace}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n statsd {\n${opt_codec}${opt_count}${opt_debug}${opt_decrement}${opt_gauge}${opt_host}${opt_increment}${opt_namespace}${opt_port}${opt_sample_rate}${opt_sender}${opt_set}${opt_timing} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
