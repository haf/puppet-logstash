# == Define: logstash::output::ganglia
#
#   This output allows you to pull metrics from your logs and ship them to
#   ganglia's gmond. This is heavily based on the graphite output.
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
# [*group*]
#   Metric group
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*host*]
#   The address of the ganglia server.
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*lifetime*]
#   Lifetime in seconds of this metric
#   Value type is number
#   Default value: 300
#   This variable is optional
#
# [*max_interval*]
#   Maximum time in seconds between gmetric calls for this metric.
#   Value type is number
#   Default value: 60
#   This variable is optional
#
# [*metric*]
#   The metric to use. This supports dynamic strings like %{host}
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*metric_type*]
#   The type of value for this metric.
#   Value can be any of: "string", "int8", "uint8", "int16", "uint16",
#   "int32", "uint32", "float", "double"
#   Default value: "uint8"
#   This variable is optional
#
# [*port*]
#   The port to connect on your ganglia server.
#   Value type is number
#   Default value: 8649
#   This variable is optional
#
# [*slope*]
#   Metric slope, represents metric behavior
#   Value can be any of: "zero", "positive", "negative", "both",
#   "unspecified"
#   Default value: "both"
#   This variable is optional
#
# [*units*]
#   Gmetric units for metric, such as "kb/sec" or "ms" or whatever unit
#   this metric uses.
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*value*]
#   The value to use. This supports dynamic strings like %{bytes} It will
#   be coerced to a floating point value. Values which cannot be coerced
#   will zero (0)
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
#  Extra information about this output can be found at:
#  http://logstash.net/docs/1.2.2.dev/outputs/ganglia
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::ganglia (
  $metric,
  $value,
  $metric_type  = '',
  $host         = '',
  $lifetime     = '',
  $max_interval = '',
  $codec        = '',
  $group        = '',
  $port         = '',
  $slope        = '',
  $units        = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_ganglia_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/ganglia/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_ganglia_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/ganglia/${name}"

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

  if ($lifetime != '') {
    if ! is_numeric($lifetime) {
      fail("\"${lifetime}\" is not a valid lifetime parameter value")
    } else {
      $opt_lifetime = "  lifetime => ${lifetime}\n"
    }
  }

  if ($max_interval != '') {
    if ! is_numeric($max_interval) {
      fail("\"${max_interval}\" is not a valid max_interval parameter value")
    } else {
      $opt_max_interval = "  max_interval => ${max_interval}\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($slope != '') {
    if ! ($slope in ['zero', 'positive', 'negative', 'both', 'unspecified']) {
      fail("\"${slope}\" is not a valid slope parameter value")
    } else {
      $opt_slope = "  slope => \"${slope}\"\n"
    }
  }

  if ($metric_type != '') {
    if ! ($metric_type in ['string', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'float', 'double']) {
      fail("\"${metric_type}\" is not a valid metric_type parameter value")
    } else {
      $opt_metric_type = "  metric_type => \"${metric_type}\"\n"
    }
  }

  if ($group != '') {
    validate_string($group)
    $opt_group = "  group => \"${group}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($units != '') {
    validate_string($units)
    $opt_units = "  units => \"${units}\"\n"
  }

  if ($value != '') {
    validate_string($value)
    $opt_value = "  value => \"${value}\"\n"
  }

  if ($metric != '') {
    validate_string($metric)
    $opt_metric = "  metric => \"${metric}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n ganglia {\n${opt_codec}${opt_group}${opt_host}${opt_lifetime}${opt_max_interval}${opt_metric}${opt_metric_type}${opt_port}${opt_slope}${opt_units}${opt_value} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
