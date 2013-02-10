# == Define: logstash::output::loggly
#
#   Got a loggly account? Use logstash to ship logs to Loggly!  This is
#   most useful so you can use logstash to parse and structure your logs
#   and ship structured, json events to your account at Loggly.  To use
#   this, you'll need to use a Loggly input with type 'http' and 'json
#   logging' enabled.
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
# [*host*]
#   The hostname to send logs to. This should target the loggly http input
#   server which is usually "logs.loggly.com"
#   Value type is string
#   Default value: "logs.loggly.com"
#   This variable is optional
#
# [*key*]
#   The loggly http input key to send to. This is usually visible in the
#   Loggly 'Inputs' page as something like this
#   https://logs.hoover.loggly.net/inputs/abcdef12-3456-7890-abcd-ef0123456789
#   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#   \----------&gt;   key   &lt;-------------/   You can use %{foo} field
#   lookups here if you need to pull the api key from the event. This is
#   mainly aimed at multitenant hosting providers who want to offer
#   shipping a customer's logs to that customer's loggly account.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*proto*]
#   Should the log action be sent over https instead of plain http
#   Value type is string
#   Default value: "http"
#   This variable is optional
#
# [*proxy_host*]
#   Proxy Host
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*proxy_password*]
#   Proxy Password
#   Value type is password
#   Default value: ""
#   This variable is optional
#
# [*proxy_port*]
#   Proxy Port
#   Value type is number
#   Default value: None
#   This variable is optional
#
# [*proxy_user*]
#   Proxy Username
#   Value type is string
#   Default value: None
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
#  http://logstash.net/docs/1.2.2.dev/outputs/loggly
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::loggly (
  $key,
  $proxy_password = '',
  $host           = '',
  $codec          = '',
  $proto          = '',
  $proxy_host     = '',
  $proxy_port     = '',
  $proxy_user     = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_loggly_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/loggly/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_loggly_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/loggly/${name}"

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

  if ($proxy_port != '') {
    if ! is_numeric($proxy_port) {
      fail("\"${proxy_port}\" is not a valid proxy_port parameter value")
    } else {
      $opt_proxy_port = "  proxy_port => ${proxy_port}\n"
    }
  }

  if ($proxy_password != '') {
    validate_string($proxy_password)
    $opt_proxy_password = "  proxy_password => \"${proxy_password}\"\n"
  }

  if ($proxy_user != '') {
    validate_string($proxy_user)
    $opt_proxy_user = "  proxy_user => \"${proxy_user}\"\n"
  }

  if ($proxy_host != '') {
    validate_string($proxy_host)
    $opt_proxy_host = "  proxy_host => \"${proxy_host}\"\n"
  }

  if ($key != '') {
    validate_string($key)
    $opt_key = "  key => \"${key}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($proto != '') {
    validate_string($proto)
    $opt_proto = "  proto => \"${proto}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n loggly {\n${opt_codec}${opt_host}${opt_key}${opt_proto}${opt_proxy_host}${opt_proxy_password}${opt_proxy_port}${opt_proxy_user} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
