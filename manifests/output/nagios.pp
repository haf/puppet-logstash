# == Define: logstash::output::nagios
#
#   The nagios output is used for sending passive check results to nagios
#   via the nagios command file.  For this output to work, your event must
#   have the following fields:  "nagios_host" "nagios_service" These
#   fields are supported, but optional:  "nagios_annotation"
#   "nagios_level" There are two configuration options:  commandfile - The
#   location of the Nagios external command file nagioslevel - Specifies
#   the level of the check to be sent. Defaults to CRITICAL and can be
#   overriden by setting the "nagioslevel" field to one of "OK",
#   "WARNING", "CRITICAL", or "UNKNOWN"   match =&gt; [ "message",
#   "(error|ERROR|CRITICAL)" ]    output{    if [message] =~
#   /(error|ERROR|CRITICAL)/ {      nagios {        # your config here
#   }    }  }
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
# [*commandfile*]
#   The path to your nagios command file
#   Value type is path
#   Default value: "/var/lib/nagios3/rw/nagios.cmd"
#   This variable is optional
#
# [*nagios_level*]
#   The Nagios check level. Should be one of 0=OK, 1=WARNING, 2=CRITICAL,
#   3=UNKNOWN. Defaults to 2 - CRITICAL.
#   Value can be any of: "0", "1", "2", "3"
#   Default value: "2"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/nagios
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::nagios (
  $codec        = '',
  $commandfile  = '',
  $nagios_level = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_nagios_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/nagios/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_nagios_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/nagios/${name}"

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

  if ($nagios_level != '') {
    if ! ($nagios_level in ['0', '1', '2', '3']) {
      fail("\"${nagios_level}\" is not a valid nagios_level parameter value")
    } else {
      $opt_nagios_level = "  nagios_level => \"${nagios_level}\"\n"
    }
  }

  if ($commandfile != '') {
    if $commandfile =~ /^puppet\:\/\// {

      validate_re($commandfile, '\Apuppet:\/\/')

      $filenameArray_commandfile = split($commandfile, '/')
      $basefilename_commandfile = $filenameArray_commandfile[-1]

      $opt_commandfile = "  commandfile => \"${filesdir}/${basefilename_commandfile}\"\n"

      file { "${filesdir}/${basefilename_commandfile}":
        source  => $commandfile,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_commandfile = "  commandfile => \"${commandfile}\"\n"
    }
  }


  #### Create the directory where we place the files
  exec { "create_files_dir_output_nagios_${name}":
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
    require => Exec["create_files_dir_output_nagios_${name}"],
    notify  => Service[$services]
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n nagios {\n${opt_codec}${opt_commandfile}${opt_nagios_level} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
