# == Define: logstash::output::xmpp
#
#   This output allows you ship events over XMPP/Jabber.  This plugin can
#   be used for posting events to humans over XMPP, or you can use it for
#   PubSub or general message passing for logstash to logstash.
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
#   The xmpp server to connect to. This is optional. If you omit this
#   setting, the host on the user/identity is used. (foo.com for
#   user@foo.com)
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*message*]
#   The message to send. This supports dynamic strings like %{host}
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*password*]
#   The xmpp password for the user/identity.
#   Value type is password
#   Default value: None
#   This variable is required
#
# [*rooms*]
#   if muc/multi-user-chat required, give the name of the room that you
#   want to join: room@conference.domain/nick
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*user*]
#   The user or resource ID, like foo@example.com.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*users*]
#   The users to send messages to
#   Value type is array
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
#  http://logstash.net/docs/1.2.2.dev/outputs/xmpp
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::xmpp (
  $message,
  $user,
  $password,
  $rooms        = '',
  $host         = '',
  $codec        = '',
  $users        = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_xmpp_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/xmpp/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_xmpp_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/xmpp/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($users != '') {
    validate_array($users)
    $arr_users = join($users, '\', \'')
    $opt_users = "  users => ['${arr_users}']\n"
  }

  if ($rooms != '') {
    validate_array($rooms)
    $arr_rooms = join($rooms, '\', \'')
    $opt_rooms = "  rooms => ['${arr_rooms}']\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($message != '') {
    validate_string($message)
    $opt_message = "  message => \"${message}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n xmpp {\n${opt_codec}${opt_host}${opt_message}${opt_password}${opt_rooms}${opt_user}${opt_users} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
