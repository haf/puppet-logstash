# == Define: logstash::output::lumberjack
#
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
# [*hosts*]
#   list of addresses lumberjack can send to
#   Value type is array
#   Default value: None
#   This variable is required
#
# [*port*]
#   the port to connect to
#   Value type is number
#   Default value: None
#   This variable is required
#
# [*ssl_certificate*]
#   ssl certificate to use
#   Value type is path
#   Default value: None
#   This variable is required
#
# [*window_size*]
#   window size
#   Value type is number
#   Default value: 5000
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
#  http://logstash.net/docs/1.2.2.dev/outputs/lumberjack
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::lumberjack (
  $ssl_certificate,
  $port,
  $hosts,
  $codec           = '',
  $window_size     = '',
  $instances       = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_lumberjack_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/lumberjack/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_lumberjack_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/lumberjack/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($hosts != '') {
    validate_array($hosts)
    $arr_hosts = join($hosts, '\', \'')
    $opt_hosts = "  hosts => ['${arr_hosts}']\n"
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

  if ($window_size != '') {
    if ! is_numeric($window_size) {
      fail("\"${window_size}\" is not a valid window_size parameter value")
    } else {
      $opt_window_size = "  window_size => ${window_size}\n"
    }
  }

  if ($ssl_certificate != '') {
    if $ssl_certificate =~ /^puppet\:\/\// {

      validate_re($ssl_certificate, '\Apuppet:\/\/')

      $filenameArray_ssl_certificate = split($ssl_certificate, '/')
      $basefilename_ssl_certificate = $filenameArray_ssl_certificate[-1]

      $opt_ssl_certificate = "  ssl_certificate => \"${filesdir}/${basefilename_ssl_certificate}\"\n"

      file { "${filesdir}/${basefilename_ssl_certificate}":
        source  => $ssl_certificate,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_ssl_certificate = "  ssl_certificate => \"${ssl_certificate}\"\n"
    }
  }


  #### Create the directory where we place the files
  exec { "create_files_dir_output_lumberjack_${name}":
    cwd     => '/',
    path    => ['/usr/bin', '/bin'],
    command => "mkdir -p ${filesdir}",
    creates => $filesdir
  }

  #### Manage the files directory
  file { $filesdir:
    ensure  => directory,
    mode    => '0640',
    purge   => true,
    recurse => true,
    require => Exec["create_files_dir_output_lumberjack_${name}"],
    notify  => Service[$services]
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n lumberjack {\n${opt_codec}${opt_hosts}${opt_port}${opt_ssl_certificate}${opt_window_size} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
