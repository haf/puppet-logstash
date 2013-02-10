# == Class: logstash::package
#
# This class exists to coordinate all software package management related
# actions, functionality and logical units in a central place.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'logstash::package': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class logstash::package(
  $ensure
) {

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  #### Package management

  # set params: in operation
  if $ensure == 'present' {

    # Check if we want to install a specific version or not
    if $logstash::common::version == false {

      $package_ensure = $logstash::common::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }

    } else {
      # install specific version
      $package_ensure = "${logstash::common::version}-1_centos"

      # Create symlink
      file { "${logstash::common::installpath}/logstash.jar":
        ensure  => 'link',
        target  => "${logstash::common::installpath}/logstash-${logstash::common::version}-flatjar.jar",
        require => Package[$logstash::params::package],
        backup  => false
      }
    }

  # set params: removal
  } else {
    $package_ensure = 'purged'
  }

  if ($logstash::common::provider == 'package') {
    # We are using a package provided by a repository
    package { $logstash::params::package:
      ensure => $package_ensure,
    }

  } elsif ($logstash::common::provider == 'custom') {
    if $ensure == 'present' {

      # We are using an external provided jar file
      if $logstash::common::jarfile == undef {
        fail('logstash needs jarfile argument when using custom provider')
      }

      if $logstash::common::installpath == undef {
        fail('logstash need installpath argument when using custom provider')
      }

      $jardir = "${logstash::common::installpath}/jars"

      # Create directory to place the jar file
      exec { 'create_install_dir':
        cwd     => '/',
        path    => ['/usr/bin', '/bin'],
        command => "mkdir -p ${logstash::common::installpath}",
        creates => $logstash::common::installpath;
      }

      # Purge old jar files
      file { $jardir:
        ensure  => 'directory',
        purge   => $logstash::common::purge_jars,
        force   => $logstash::common::purge_jars,
        require => Exec['create_install_dir'],
      }

      # Create log directory
      exec { 'create_log_dir':
        cwd     => '/',
        path    => ['/usr/bin', '/bin'],
        command => "mkdir -p ${logstash::params::logdir}",
        creates => $logstash::params::logdir;
      }

      file { $logstash::params::logdir:
        ensure  => 'directory',
        owner   => $logstash::common::user,
        group   => $logstash::common::group,
        require => Exec['create_log_dir'],
      }

      # Place the jar file
      $filenameArray = split($logstash::common::jarfile, '/')
      $basefilename = $filenameArray[-1]

      $sourceArray = split($logstash::common::jarfile, ':')
      $protocol_type = $sourceArray[0]

      case $protocol_type {
        puppet: {

          file { "${jardir}/${basefilename}":
            ensure  => present,
            source  => $logstash::common::jarfile,
            require => File[$jardir],
            backup  => false,
          }

          File["${jardir}/${basefilename}"] -> File["${logstash::common::installpath}/logstash.jar"]

        }
        ftp, https, http: {

          exec { 'download-logstash':
            command => "wget -O ${jardir}/${basefilename} ${$logstash::common::jarfile} 2> /dev/null",
            path    => ['/usr/bin', '/bin'],
            creates => "${jardir}/${basefilename}",
            require => Exec['create_install_dir'],
          }

          Exec['download-logstash'] -> File["${logstash::common::installpath}/logstash.jar"]

        }
        default: {
          fail('Protocol must be puppet, http, https, or ftp.')
        }
      }

      # Create symlink
      file { "${logstash::common::installpath}/logstash.jar":
        ensure  => 'link',
        target  => "${jardir}/${basefilename}",
        backup  => false
      }

    } else {

      # If not present, remove installpath, leave logfiles
      file { $logstash::common::installpath:
        ensure  => 'absent',
        force   => true,
        recurse => true,
        purge   => true,
      }
    }

  }
}
