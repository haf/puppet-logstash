# == Define: logstash::output::exec
#
#   This output will run a command for any matching event.  Example:
#   output {   exec {     type =&gt; abuse     command =&gt; "iptables -A
#   INPUT -s %{clientip} -j DROP"   } }   Run subprocesses via system ruby
#   function  WARNING: if you want it non-blocking you should use &amp; or
#   dtach or other such techniques
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
# [*command*]
#   Command line to execute via subprocess. Use dtach or screen to make it
#   non blocking
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
#  http://logstash.net/docs/1.2.2.dev/outputs/exec
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::exec (
  $command,
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
    $conffiles    = suffix($confdirstart, "/config/output_exec_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/exec/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_exec_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/exec/${name}"

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

  if ($command != '') {
    validate_string($command)
    $opt_command = "  command => \"${command}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n exec {\n${opt_codec}${opt_command} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
