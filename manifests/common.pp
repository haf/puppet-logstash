class logstash::common(
  $ensure      = 'present',
  $user        = 'logstash',
  $group       = 'logstash',
  $autoupgrade = false,
  # installpath requires switching dep on OS
  $installpath = $logstash::params::installpath,
  $provider    = 'package',
  $version     = false,
  $jarfile     = undef,
  $purge_jars  = true,
) inherits logstash::params {

  #### Validate parameters
  validate_bool($autoupgrade, $purge_jars)

  # ensure
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail("\"${ensure}\" is not a valid ensure parameter value")
  }

  #### Resources
  class { 'logstash::package':
    ensure => $ensure,
  }

  group { $group:
    ensure => present,
    system => true,
  }
}