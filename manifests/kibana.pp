class logstash::kibana {
  user { $logstash::common::user:
    system  => true,
    gid     => $logstash::common::group,
    require => Class['logstash::common'],
  }

  svcutils::mixsvc { 'logstash-kibana':
    user        => $logstash::common::user,
    group       => $logstash::common::group,
    log_dir     => '/var/log/logstash',
    exec        => "java -jar /opt/logstash/logstash.jar web",
    description => 'LogStash kibana GUI',
  }

  firewall { "201 allow logstash::web:9292":
    proto   => 'tcp',
    state   => ['NEW'],
    dport   => 9292,
    action  => 'accept',
  }
}