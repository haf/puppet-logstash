# == Define: logstash::output::pipe
#
#   Pipe output.  Pipe events to stdin of another program. You can use
#   fields from the event as parts of the command. WARNING: This feature
#   can cause logstash to fork off multiple children if you are not
#   carefull with per-event commandline.
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
#   Command line to launch and pipe to
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*message_format*]
#   The format to use when writing events to the pipe. This value supports
#   any string and can include %{name} and other dynamic strings.  If this
#   setting is omitted, the full json representation of the event will be
#   written as a single line.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*ttl*]
#   Close pipe that hasn't been used for TTL seconds. -1 or 0 means never
#   close.
#   Value type is number
#   Default value: 10
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
#  http://logstash.net/docs/1.2.2.dev/outputs/pipe
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::pipe (
  $command,
  $message_format = '',
  $codec          = '',
  $ttl            = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_pipe_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/pipe/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_pipe_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/pipe/${name}"

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

  if ($ttl != '') {
    if ! is_numeric($ttl) {
      fail("\"${ttl}\" is not a valid ttl parameter value")
    } else {
      $opt_ttl = "  ttl => ${ttl}\n"
    }
  }

  if ($command != '') {
    validate_string($command)
    $opt_command = "  command => \"${command}\"\n"
  }

  if ($message_format != '') {
    validate_string($message_format)
    $opt_message_format = "  message_format => \"${message_format}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n pipe {\n${opt_codec}${opt_command}${opt_message_format}${opt_ttl} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
