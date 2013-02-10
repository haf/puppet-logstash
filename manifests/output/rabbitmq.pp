# == Define: logstash::output::rabbitmq
#
#   Push events to a RabbitMQ exchange. Requires RabbitMQ 2.x or later
#   version (3.x is recommended).  Relevant links:  RabbitMQ:
#   http://www.rabbitmq.com/ HotBunnies: http://hotbunnies.info Bunny:
#   http://rubybunny.info
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
# [*debug*]
#   Enable or disable logging
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*durable*]
#   Is this exchange durable? (aka; Should it survive a broker restart?)
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*exchange*]
#   The name of the exchange
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*exchange_type*]
#   Exchange  The exchange type (fanout, topic, direct)
#   Value can be any of: "fanout", "direct", "topic"
#   Default value: None
#   This variable is required
#
# [*host*]
#   Connection  RabbitMQ server address
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*key*]
#   Key to route to by default. Defaults to 'logstash'  Routing keys are
#   ignored on fanout exchanges.
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*password*]
#   RabbitMQ password
#   Value type is password
#   Default value: "guest"
#   This variable is optional
#
# [*persistent*]
#   Should RabbitMQ persist messages to disk?
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*port*]
#   RabbitMQ port to connect on
#   Value type is number
#   Default value: 5672
#   This variable is optional
#
# [*ssl*]
#   Enable or disable SSL
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*user*]
#   RabbitMQ username
#   Value type is string
#   Default value: "guest"
#   This variable is optional
#
# [*verify_ssl*]
#   Validate SSL certificate
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*vhost*]
#   The vhost to use. If you don't know what this is, leave the default.
#   Value type is string
#   Default value: "/"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/rabbitmq
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::rabbitmq (
  $exchange,
  $host,
  $exchange_type,
  $persistent    = '',
  $durable       = '',
  $debug         = '',
  $key           = '',
  $password      = '',
  $codec         = '',
  $port          = '',
  $ssl           = '',
  $user          = '',
  $verify_ssl    = '',
  $vhost         = '',
  $instances     = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_rabbitmq_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/rabbitmq/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_rabbitmq_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/rabbitmq/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($verify_ssl != '') {
    validate_bool($verify_ssl)
    $opt_verify_ssl = "  verify_ssl => ${verify_ssl}\n"
  }

  if ($durable != '') {
    validate_bool($durable)
    $opt_durable = "  durable => ${durable}\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($ssl != '') {
    validate_bool($ssl)
    $opt_ssl = "  ssl => ${ssl}\n"
  }

  if ($persistent != '') {
    validate_bool($persistent)
    $opt_persistent = "  persistent => ${persistent}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($exchange_type != '') {
    if ! ($exchange_type in ['fanout', 'direct', 'topic']) {
      fail("\"${exchange_type}\" is not a valid exchange_type parameter value")
    } else {
      $opt_exchange_type = "  exchange_type => \"${exchange_type}\"\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($key != '') {
    validate_string($key)
    $opt_key = "  key => \"${key}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($exchange != '') {
    validate_string($exchange)
    $opt_exchange = "  exchange => \"${exchange}\"\n"
  }

  if ($vhost != '') {
    validate_string($vhost)
    $opt_vhost = "  vhost => \"${vhost}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n rabbitmq {\n${opt_codec}${opt_debug}${opt_durable}${opt_exchange}${opt_exchange_type}${opt_host}${opt_key}${opt_password}${opt_persistent}${opt_port}${opt_ssl}${opt_user}${opt_verify_ssl}${opt_vhost} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
