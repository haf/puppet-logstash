# == Define: logstash::output::graphtastic
#
#   A plugin for a newly developed Java/Spring Metrics application I
#   didn't really want to code this project but I couldn't find a
#   respectable alternative that would also run on any Windows machine -
#   which is the problem and why I am not going with Graphite and statsd.
#   This application provides multiple integration options so as to make
#   its use under your network requirements possible. This includes a REST
#   option that is always enabled for your use in case you want to write a
#   small script to send the occasional metric data.  Find GraphTastic
#   here : https://github.com/NickPadilla/GraphTastic
#
#
# === Parameters
#
# [*batch_number*]
#   the number of metrics to send to GraphTastic at one time. 60 seems to
#   be the perfect amount for UDP, with default packet size.
#   Value type is number
#   Default value: 60
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*context*]
#   if using rest as your end point you need to also provide the
#   application url it defaults to localhost/graphtastic.  You can
#   customize the application url by changing the name of the .war file.
#   There are other ways to change the application context, but they vary
#   depending on the Application Server in use. Please consult your
#   application server documentation for more on application contexts.
#   Value type is string
#   Default value: "graphtastic"
#   This variable is optional
#
# [*error_file*]
#   setting allows you to specify where we save errored transactions this
#   makes the most sense at this point - will need to decide on how we
#   reintegrate these error metrics NOT IMPLEMENTED!
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*host*]
#   host for the graphtastic server - defaults to 127.0.0.1
#   Value type is string
#   Default value: "127.0.0.1"
#   This variable is optional
#
# [*integration*]
#   options are udp(fastest - default) - rmi(faster) - rest(fast) -
#   tcp(don't use TCP yet - some problems - errors out on linux)
#   Value can be any of: "udp", "tcp", "rmi", "rest"
#   Default value: "udp"
#   This variable is optional
#
# [*metrics*]
#   metrics hash - you will provide a name for your metric and the metric
#   data as key value pairs.  so for example:  metrics =&gt; { "Response"
#   =&gt; "%{response}" }  example for the logstash config  metrics =&gt;
#   [ "Response", "%{response}" ]  NOTE: you can also use the dynamic
#   fields for the key value as well as the actual value
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*port*]
#   port for the graphtastic instance - defaults to 1199 for RMI, 1299 for
#   TCP, 1399 for UDP, and 8080 for REST
#   Value type is number
#   Default value: None
#   This variable is optional
#
# [*retries*]
#   number of attempted retry after send error - currently only way to
#   integrate errored transactions - should try and save to a file or
#   later consumption either by graphtastic utility or by this program
#   after connectivity is ensured to be established.
#   Value type is number
#   Default value: 1
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
#  http://logstash.net/docs/1.2.2.dev/outputs/graphtastic
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::graphtastic (
  $batch_number = '',
  $codec        = '',
  $context      = '',
  $error_file   = '',
  $host         = '',
  $integration  = '',
  $metrics      = '',
  $port         = '',
  $retries      = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_graphtastic_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/graphtastic/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_graphtastic_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/graphtastic/${name}"

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

  if ($metrics != '') {
    validate_hash($metrics)
    $var_metrics = $metrics
    $arr_metrics = inline_template('<%= "["+@var_metrics.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_metrics = "  metrics => ${arr_metrics}\n"
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($retries != '') {
    if ! is_numeric($retries) {
      fail("\"${retries}\" is not a valid retries parameter value")
    } else {
      $opt_retries = "  retries => ${retries}\n"
    }
  }

  if ($batch_number != '') {
    if ! is_numeric($batch_number) {
      fail("\"${batch_number}\" is not a valid batch_number parameter value")
    } else {
      $opt_batch_number = "  batch_number => ${batch_number}\n"
    }
  }

  if ($integration != '') {
    if ! ($integration in ['udp', 'tcp', 'rmi', 'rest']) {
      fail("\"${integration}\" is not a valid integration parameter value")
    } else {
      $opt_integration = "  integration => \"${integration}\"\n"
    }
  }

  if ($context != '') {
    validate_string($context)
    $opt_context = "  context => \"${context}\"\n"
  }

  if ($error_file != '') {
    validate_string($error_file)
    $opt_error_file = "  error_file => \"${error_file}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n graphtastic {\n${opt_batch_number}${opt_codec}${opt_context}${opt_error_file}${opt_host}${opt_integration}${opt_metrics}${opt_port}${opt_retries} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
