# == Define: logstash::output::pagerduty
#
#   PagerDuty output Send specific events to PagerDuty for alerting
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
# [*description*]
#   Custom description
#   Value type is string
#   Default value: "Logstash event for %{host}"
#   This variable is optional
#
# [*details*]
#   Event details These might be keys from the logstash event you wish to
#   include tags are automatically included if detected so no need to add
#   them here
#   Value type is hash
#   Default value: {"timestamp"=>"%{@timestamp}", "message"=>"%{message}"}
#   This variable is optional
#
# [*event_type*]
#   Event type
#   Value can be any of: "trigger", "acknowledge", "resolve"
#   Default value: "trigger"
#   This variable is optional
#
# [*incident_key*]
#   The service key to use You'll need to set this up in PD beforehand
#   Value type is string
#   Default value: "logstash/%{host}/%{type}"
#   This variable is optional
#
# [*pdurl*]
#   PagerDuty API url You shouldn't need to change this This allows for
#   flexibility should PD iterate the API and Logstash hasn't updated yet
#   Value type is string
#   Default value: "https://events.pagerduty.com/generic/2010-04-15/create_event.json"
#   This variable is optional
#
# [*service_key*]
#   Service API Key
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
#  http://logstash.net/docs/1.2.2.dev/outputs/pagerduty
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::pagerduty (
  $service_key,
  $incident_key = '',
  $details      = '',
  $event_type   = '',
  $description  = '',
  $pdurl        = '',
  $codec        = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_pagerduty_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/pagerduty/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_pagerduty_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/pagerduty/${name}"

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

  if ($details != '') {
    validate_hash($details)
    $var_details = $details
    $arr_details = inline_template('<%= "["+@var_details.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_details = "  details => ${arr_details}\n"
  }

  if ($event_type != '') {
    if ! ($event_type in ['trigger', 'acknowledge', 'resolve']) {
      fail("\"${event_type}\" is not a valid event_type parameter value")
    } else {
      $opt_event_type = "  event_type => \"${event_type}\"\n"
    }
  }

  if ($service_key != '') {
    validate_string($service_key)
    $opt_service_key = "  service_key => \"${service_key}\"\n"
  }

  if ($pdurl != '') {
    validate_string($pdurl)
    $opt_pdurl = "  pdurl => \"${pdurl}\"\n"
  }

  if ($description != '') {
    validate_string($description)
    $opt_description = "  description => \"${description}\"\n"
  }

  if ($incident_key != '') {
    validate_string($incident_key)
    $opt_incident_key = "  incident_key => \"${incident_key}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n pagerduty {\n${opt_codec}${opt_description}${opt_details}${opt_event_type}${opt_incident_key}${opt_pdurl}${opt_service_key} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
