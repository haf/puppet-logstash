# == Class: logstash::config
#
# This class exists to coordinate all configuration related actions,
# functionality and logical units in a central place.
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
#   class { 'logstash::config': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class logstash::config {

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  user { $logstash::logstash_user:
    gid     => $logstash::common::group,
    home    => $logstash::installpath,
    shell   => '/bin/bash',
    system  => true,
    require => Group[$logstash::common::group],
  }

  file { $logstash::installpath:
    ensure => directory,
    owner  => $logstash::logstash_user,
    group  => $logstash::common::group,
    mode   => '0755',
    require => User[$logstash::logstash_user],
  }

  if $logstash::multi_instance == true {

    # Setup and manage config dirs for the instances
    logstash::configdir { $logstash::instances:; }

  } else {

    # Manage the single config dir
    file { "${logstash::configdir}/conf.d":
      ensure  => directory,
      mode    => '0640',
      purge   => true,
      recurse => true,
      notify  => Service['logstash']
    }
  }

  $tmp_dir = "${logstash::installpath}/tmp"

  #### Create the tmp dir
  exec { 'create_tmp_dir':
    cwd     => '/',
    path    => ['/usr/bin', '/bin'],
    command => "mkdir -p ${tmp_dir}",
    creates => $tmp_dir;
  }

  file { $tmp_dir:
    ensure  => directory,
    mode    => '0640',
    require => Exec[ 'create_tmp_dir' ]
  }
}
