# == Define: logstash::output::librato
#
#
#
# === Parameters
#
# [*account_id*]
#   This output lets you send metrics, annotations and alerts to Librato
#   based on Logstash events  This is VERY experimental and inefficient
#   right now. Your Librato account usually an email address
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*annotation*]
#   Annotations Registers an annotation with Librato The only required
#   field is title and name. start_time and end_time will be set to
#   event["@timestamp"].to_i You can add any other optional annotation
#   values as well. All values will be passed through event.sprintf
#   Example:   ["title":"Logstash event on %{host}",
#   "name":"logstashstream"] or   ["title":"Logstash event",
#   "description":"%{message}", "name":"logstashstream"]
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*api_token*]
#   Your Librato API Token
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*batch_size*]
#   Batch size Number of events to batch up before sending to Librato.
#   Value type is string
#   Default value: "10"
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*counter*]
#   Counters Send data to Librato as a counter  Example:   ["value", "1",
#   "source", "%{host}", "name", "messagesreceived"] Additionally, you can
#   override the measure_time for the event. Must be a unix timestamp:
#   ["value", "1", "source", "%{host}", "name", "messagesreceived",
#   "measuretime", "%{myunixtime_field}"] Default is to use the event's
#   timestamp
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*gauge*]
#   Gauges Send data to Librato as a gauge  Example:   ["value",
#   "%{bytesrecieved}", "source", "%{host}", "name", "apachebytes"]
#   Additionally, you can override the measure_time for the event. Must be
#   a unix timestamp:   ["value", "%{bytesrecieved}", "source", "%{host}",
#   "name", "apachebytes","measuretime", "%{myunixtime_field}] Default is
#   to use the event's timestamp
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
#  http://logstash.net/docs/1.2.2.dev/outputs/librato
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::librato (
  $account_id,
  $api_token,
  $counter      = '',
  $batch_size   = '',
  $codec        = '',
  $annotation   = '',
  $gauge        = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_librato_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/librato/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_librato_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/librato/${name}"

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

  if ($annotation != '') {
    validate_hash($annotation)
    $var_annotation = $annotation
    $arr_annotation = inline_template('<%= "["+@var_annotation.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_annotation = "  annotation => ${arr_annotation}\n"
  }

  if ($gauge != '') {
    validate_hash($gauge)
    $var_gauge = $gauge
    $arr_gauge = inline_template('<%= "["+@var_gauge.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_gauge = "  gauge => ${arr_gauge}\n"
  }

  if ($counter != '') {
    validate_hash($counter)
    $var_counter = $counter
    $arr_counter = inline_template('<%= "["+@var_counter.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_counter = "  counter => ${arr_counter}\n"
  }

  if ($batch_size != '') {
    validate_string($batch_size)
    $opt_batch_size = "  batch_size => \"${batch_size}\"\n"
  }

  if ($api_token != '') {
    validate_string($api_token)
    $opt_api_token = "  api_token => \"${api_token}\"\n"
  }

  if ($account_id != '') {
    validate_string($account_id)
    $opt_account_id = "  account_id => \"${account_id}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n librato {\n${opt_account_id}${opt_annotation}${opt_api_token}${opt_batch_size}${opt_codec}${opt_counter}${opt_gauge} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
