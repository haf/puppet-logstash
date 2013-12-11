class logstash::kibana(
  $ensure          = 'present',
  $manage_firewall = hiera('manage_firewall', false),
  $firewall_subnet = '0.0.0.0/0'
) {
  include ::logstash::common

  user { $logstash::common::user:
    ensure  => $ensure,
    gid     => $logstash::common::group,
    home    => "/opt/logstash",
    system  => true,
    require => Class['logstash::common'],
  }

  supervisor::service { 'logstash-kibana':
    ensure  => $ensure,
    command => 'java -jar /opt/logstash/logstash.jar web',
    user    => $logstash::common::user,
    group   => $logstash::common::group,
    require => User[$logstash::common::user],
  }

  if $manage_firewall {
    firewall { "201 allow logstash::web:9292":
      proto   => 'tcp',
      state   => ['NEW'],
      dport   => 9292,
      action  => 'accept',
      source  => $firewall_subnet,
    }
  }
}
