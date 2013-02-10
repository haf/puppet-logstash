# == Define: logstash::output::irc
#
#   Write events to IRC
#
#
# === Parameters
#
# [*channels*]
#   Channels to broadcast to.  These should be full channel names
#   including the '#' symbol, such as "#logstash".
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
# [*format*]
#   Message format to send, event tokens are usable here
#   Value type is string
#   Default value: "%{message}"
#   This variable is optional
#
# [*host*]
#   Address of the host to connect to
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*messages_per_second*]
#   Limit the rate of messages sent to IRC in messages per second.
#   Value type is number
#   Default value: 0.5
#   This variable is optional
#
# [*nick*]
#   IRC Nickname
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*password*]
#   IRC server password
#   Value type is password
#   Default value: None
#   This variable is optional
#
# [*port*]
#   Port on host to connect to.
#   Value type is number
#   Default value: 6667
#   This variable is optional
#
# [*real*]
#   IRC Real name
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*secure*]
#   Set this to true to enable SSL.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*user*]
#   IRC Username
#   Value type is string
#   Default value: "logstash"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/irc
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::irc (
  $channels,
  $host,
  $password            = '',
  $format              = '',
  $codec               = '',
  $messages_per_second = '',
  $nick                = '',
  $port                = '',
  $real                = '',
  $secure              = '',
  $user                = '',
  $instances           = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_irc_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/irc/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_irc_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/irc/${name}"

  }

  #### Validate parameters
  if ($channels != '') {
    validate_array($channels)
    $arr_channels = join($channels, '\', \'')
    $opt_channels = "  channels => ['${arr_channels}']\n"
  }


  validate_array($instances)

  if ($secure != '') {
    validate_bool($secure)
    $opt_secure = "  secure => ${secure}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($messages_per_second != '') {
    if ! is_numeric($messages_per_second) {
      fail("\"${messages_per_second}\" is not a valid messages_per_second parameter value")
    } else {
      $opt_messages_per_second = "  messages_per_second => ${messages_per_second}\n"
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

  if ($real != '') {
    validate_string($real)
    $opt_real = "  real => \"${real}\"\n"
  }

  if ($format != '') {
    validate_string($format)
    $opt_format = "  format => \"${format}\"\n"
  }

  if ($nick != '') {
    validate_string($nick)
    $opt_nick = "  nick => \"${nick}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n irc {\n${opt_channels}${opt_codec}${opt_format}${opt_host}${opt_messages_per_second}${opt_nick}${opt_password}${opt_port}${opt_real}${opt_secure}${opt_user} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
