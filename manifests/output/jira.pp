# == Define: logstash::output::jira
#
#   Origin
#   https://groups.google.com/forum/#!msg/logstash-users/exgrB4iQ-mw/R34apku5nXsJ
#   and https://botbot.me/freenode/logstash/msg/4169496/ via
#   https://gist.github.com/electrical/4660061e8fff11cdcf37#file-jira-rb
#   Uses jiralicious as the bridge to JIRA By Martin Cleaver, Blended
#   Perspectives with a lot of help from 'electrical' in #logstash  This
#   is so is most useful so you can use logstash to parse and structure
#   your logs and ship structured, json events to JIRA  To use this,
#   you'll need to ensure your JIRA instance allows REST calls
#
#
# === Parameters
#
# [*assignee*]
#   JIRA Reporter
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*host*]
#   The hostname to send logs to. This should target your JIRA server and
#   has to have the REST interface enabled
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*issuetypeid*]
#   JIRA Issuetype number
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*password*]
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*priority*]
#   JIRA Priority
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*projectid*]
#   Javalicious has no proxy support JIRA Project number
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*reporter*]
#   JIRA Reporter
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*summary*]
#   JIRA Summary
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*username*]
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
#  http://logstash.net/docs/1.2.2.dev/outputs/jira
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::jira (
  $projectid,
  $username,
  $summary,
  $priority,
  $issuetypeid,
  $password,
  $assignee     = '',
  $host         = '',
  $reporter     = '',
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
    $conffiles    = suffix($confdirstart, "/config/output_jira_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/jira/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_jira_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/jira/${name}"

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

  if ($projectid != '') {
    validate_string($projectid)
    $opt_projectid = "  projectid => \"${projectid}\"\n"
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($priority != '') {
    validate_string($priority)
    $opt_priority = "  priority => \"${priority}\"\n"
  }

  if ($issuetypeid != '') {
    validate_string($issuetypeid)
    $opt_issuetypeid = "  issuetypeid => \"${issuetypeid}\"\n"
  }

  if ($reporter != '') {
    validate_string($reporter)
    $opt_reporter = "  reporter => \"${reporter}\"\n"
  }

  if ($summary != '') {
    validate_string($summary)
    $opt_summary = "  summary => \"${summary}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($username != '') {
    validate_string($username)
    $opt_username = "  username => \"${username}\"\n"
  }

  if ($assignee != '') {
    validate_string($assignee)
    $opt_assignee = "  assignee => \"${assignee}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n jira {\n${opt_assignee}${opt_codec}${opt_host}${opt_issuetypeid}${opt_password}${opt_priority}${opt_projectid}${opt_reporter}${opt_summary}${opt_username} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
