# == Define: logstash::output::hipchat
#
#   This output allows you to write events to HipChat.
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
# [*color*]
#   Background color for message. HipChat currently supports one of
#   "yellow", "red", "green", "purple", "gray", or "random". (default:
#   yellow)
#   Value type is string
#   Default value: "yellow"
#   This variable is optional
#
# [*format*]
#   Message format to send, event tokens are usable here.
#   Value type is string
#   Default value: "%{message}"
#   This variable is optional
#
# [*from*]
#   The name the message will appear be sent from.
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*room_id*]
#   The ID or name of the room.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*token*]
#   The HipChat authentication token.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*trigger_notify*]
#   Whether or not this message should trigger a notification for people
#   in the room.
#   Value type is boolean
#   Default value: false
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
#  http://logstash.net/docs/1.2.2.dev/outputs/hipchat
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::hipchat (
  $room_id,
  $token,
  $codec          = '',
  $format         = '',
  $from           = '',
  $color          = '',
  $trigger_notify = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_hipchat_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/hipchat/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_hipchat_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/hipchat/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($trigger_notify != '') {
    validate_bool($trigger_notify)
    $opt_trigger_notify = "  trigger_notify => ${trigger_notify}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($from != '') {
    validate_string($from)
    $opt_from = "  from => \"${from}\"\n"
  }

  if ($format != '') {
    validate_string($format)
    $opt_format = "  format => \"${format}\"\n"
  }

  if ($token != '') {
    validate_string($token)
    $opt_token = "  token => \"${token}\"\n"
  }

  if ($color != '') {
    validate_string($color)
    $opt_color = "  color => \"${color}\"\n"
  }

  if ($room_id != '') {
    validate_string($room_id)
    $opt_room_id = "  room_id => \"${room_id}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n hipchat {\n${opt_codec}${opt_color}${opt_format}${opt_from}${opt_room_id}${opt_token}${opt_trigger_notify} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
