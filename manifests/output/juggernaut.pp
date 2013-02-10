# == Define: logstash::output::juggernaut
#
#   Push messages to the juggernaut websockets server:
#   https://github.com/maccman/juggernaut Wraps Websockets and supports
#   other methods (including xhr longpolling) This is basically, just an
#   extension of the redis output (Juggernaut pulls messages from redis).
#   But it pushes messages to a particular channel and formats the
#   messages in the way juggernaut expects.
#
#
# === Parameters
#
# [*channels*]
#   List of channels to which to publish. Dynamic names are valid here,
#   for example "logstash-%{type}".
#   Value type is array
#   Default value: None
#   This variable is required
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*db*]
#   The redis database number.
#   Value type is number
#   Default value: 0
#   This variable is optional
#
# [*host*]
#   The hostname of the redis server to which juggernaut is listening.
#   Value type is string
#   Default value: "127.0.0.1"
#   This variable is optional
#
# [*message_format*]
#   How should the message be formatted before pushing to the websocket.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*password*]
#   Password to authenticate with.  There is no authentication by default.
#   Value type is password
#   Default value: None
#   This variable is optional
#
# [*port*]
#   The port to connect on.
#   Value type is number
#   Default value: 6379
#   This variable is optional
#
# [*timeout*]
#   Redis initial connection timeout in seconds.
#   Value type is number
#   Default value: 5
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
#  http://logstash.net/docs/1.2.2.dev/outputs/juggernaut
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::juggernaut (
  $channels,
  $password       = '',
  $db             = '',
  $host           = '',
  $message_format = '',
  $codec          = '',
  $port           = '',
  $timeout        = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_juggernaut_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/juggernaut/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_juggernaut_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/juggernaut/${name}"

  }

  #### Validate parameters
  if ($channels != '') {
    validate_array($channels)
    $arr_channels = join($channels, '\', \'')
    $opt_channels = "  channels => ['${arr_channels}']\n"
  }


  validate_array($instances)

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($db != '') {
    if ! is_numeric($db) {
      fail("\"${db}\" is not a valid db parameter value")
    } else {
      $opt_db = "  db => ${db}\n"
    }
  }

  if ($timeout != '') {
    if ! is_numeric($timeout) {
      fail("\"${timeout}\" is not a valid timeout parameter value")
    } else {
      $opt_timeout = "  timeout => ${timeout}\n"
    }
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($message_format != '') {
    validate_string($message_format)
    $opt_message_format = "  message_format => \"${message_format}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n juggernaut {\n${opt_channels}${opt_codec}${opt_db}${opt_host}${opt_message_format}${opt_password}${opt_port}${opt_timeout} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
