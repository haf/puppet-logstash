# == Define: logstash::output::circonus
#
#
#
# === Parameters
#
# [*annotation*]
#   Annotations Registers an annotation with Circonus The only required
#   field is title and description. start and stop will be set to
#   event["@timestamp"] You can add any other optional annotation values
#   as well. All values will be passed through event.sprintf  Example:
#   ["title":"Logstash event", "description":"Logstash event for %{host}"]
#   or   ["title":"Logstash event", "description":"Logstash event for
#   %{host}", "parent_id", "1"]
#   Value type is hash
#   Default value: {}
#   This variable is required
#
# [*api_token*]
#   This output lets you send annotations to Circonus based on Logstash
#   events  Your Circonus API Token
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*app_name*]
#   Your Circonus App name This will be passed through event.sprintf so
#   variables are allowed here:  Example:  app_name =&gt; "%{myappname}"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/circonus
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::circonus (
  $annotation,
  $api_token,
  $app_name,
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
    $conffiles    = suffix($confdirstart, "/config/output_circonus_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/circonus/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_circonus_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/circonus/${name}"

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

  if ($app_name != '') {
    validate_string($app_name)
    $opt_app_name = "  app_name => \"${app_name}\"\n"
  }

  if ($api_token != '') {
    validate_string($api_token)
    $opt_api_token = "  api_token => \"${api_token}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n circonus {\n${opt_annotation}${opt_api_token}${opt_app_name}${opt_codec} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
