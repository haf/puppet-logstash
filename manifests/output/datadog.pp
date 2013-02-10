# == Define: logstash::output::datadog
#
#
#
# === Parameters
#
# [*alert_type*]
#   Alert type
#   Value can be any of: "info", "error", "warning", "success"
#   Default value: None
#   This variable is optional
#
# [*api_key*]
#   This output lets you send events (for now. soon metrics) to DataDogHQ
#   based on Logstash events  Note that since Logstash maintains no state
#   these will be one-shot events  Your DatadogHQ API key
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
# [*date_happened*]
#   Date Happened
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*dd_tags*]
#   Tags Set any custom tags for this event Default are the Logstash tags
#   if any
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*priority*]
#   Priority
#   Value can be any of: "normal", "low"
#   Default value: None
#   This variable is optional
#
# [*source_type_name*]
#   Source type name
#   Value can be any of: "nagios", "hudson", "jenkins", "user", "my apps",
#   "feed", "chef", "puppet", "git", "bitbucket", "fabric", "capistrano"
#   Default value: "my apps"
#   This variable is optional
#
# [*text*]
#   Text
#   Value type is string
#   Default value: "%{message}"
#   This variable is optional
#
# [*title*]
#   Title
#   Value type is string
#   Default value: "Logstash event for %{host}"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/datadog
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::datadog (
  $api_key,
  $priority         = '',
  $codec            = '',
  $date_happened    = '',
  $dd_tags          = '',
  $alert_type       = '',
  $source_type_name = '',
  $text             = '',
  $title            = '',
  $instances        = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_datadog_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/datadog/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_datadog_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/datadog/${name}"

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

  if ($priority != '') {
    if ! ($priority in ['normal', 'low']) {
      fail("\"${priority}\" is not a valid priority parameter value")
    } else {
      $opt_priority = "  priority => \"${priority}\"\n"
    }
  }

  if ($alert_type != '') {
    if ! ($alert_type in ['info', 'error', 'warning', 'success']) {
      fail("\"${alert_type}\" is not a valid alert_type parameter value")
    } else {
      $opt_alert_type = "  alert_type => \"${alert_type}\"\n"
    }
  }

  if ($source_type_name != '') {
    if ! ($source_type_name in ['nagios', 'hudson', 'jenkins', 'user', 'my apps', 'feed', 'chef', 'puppet', 'git', 'bitbucket', 'fabric', 'capistrano']) {
      fail("\"${source_type_name}\" is not a valid source_type_name parameter value")
    } else {
      $opt_source_type_name = "  source_type_name => \"${source_type_name}\"\n"
    }
  }

  if ($text != '') {
    validate_string($text)
    $opt_text = "  text => \"${text}\"\n"
  }

  if ($api_key != '') {
    validate_string($api_key)
    $opt_api_key = "  api_key => \"${api_key}\"\n"
  }

  if ($title != '') {
    validate_string($title)
    $opt_title = "  title => \"${title}\"\n"
  }

  if ($date_happened != '') {
    validate_string($date_happened)
    $opt_date_happened = "  date_happened => \"${date_happened}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n datadog {\n${opt_alert_type}${opt_api_key}${opt_codec}${opt_date_happened}${opt_dd_tags}${opt_priority}${opt_source_type_name}${opt_text}${opt_title} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
