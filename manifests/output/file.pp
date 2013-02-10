# == Define: logstash::output::file
#
#   File output.  Write events to files on disk. You can use fields from
#   the event as parts of the filename.
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
# [*flush_interval*]
#   Flush interval for flushing writes to log files. 0 will flush on every
#   meesage
#   Value type is number
#   Default value: 2
#   This variable is optional
#
# [*gzip*]
#   Gzip output stream
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*max_size*]
#   The maximum size of file to write. When the file exceeds this
#   threshold, it will be rotated to the current filename + ".1" If that
#   file already exists, the previous .1 will shift to .2 and so forth.
#   NOT YET SUPPORTED
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*message_format*]
#   The format to use when writing events to the file. This value supports
#   any string and can include %{name} and other dynamic strings.  If this
#   setting is omitted, the full json representation of the event will be
#   written as a single line.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*path*]
#   The path to the file to write. Event fields can be used here, like
#   "/var/log/logstash/%{host}/%{application}" One may also utilize the
#   path option for date-based log rotation via the joda time format. This
#   will use the event timestamp. E.g.: path =&gt;
#   "./test-%{+YYYY-MM-dd}.txt" to create ./test-2013-05-29.txt
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
#  http://logstash.net/docs/1.2.2.dev/outputs/file
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::file (
  $path,
  $message_format = '',
  $flush_interval = '',
  $gzip           = '',
  $max_size       = '',
  $codec          = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_file_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/file/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_file_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/file/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($gzip != '') {
    validate_bool($gzip)
    $opt_gzip = "  gzip => ${gzip}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($flush_interval != '') {
    if ! is_numeric($flush_interval) {
      fail("\"${flush_interval}\" is not a valid flush_interval parameter value")
    } else {
      $opt_flush_interval = "  flush_interval => ${flush_interval}\n"
    }
  }

  if ($max_size != '') {
    validate_string($max_size)
    $opt_max_size = "  max_size => \"${max_size}\"\n"
  }

  if ($path != '') {
    validate_string($path)
    $opt_path = "  path => \"${path}\"\n"
  }

  if ($message_format != '') {
    validate_string($message_format)
    $opt_message_format = "  message_format => \"${message_format}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n file {\n${opt_codec}${opt_flush_interval}${opt_gzip}${opt_max_size}${opt_message_format}${opt_path} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
