# == Define: logstash::output::zabbix
#
#   The zabbix output is used for sending item data to zabbix via the
#   zabbix_sender executable.  For this output to work, your event must
#   have the following fields:  "zabbix_host"    (the host configured in
#   Zabbix) "zabbix_item"    (the item key on the host in Zabbix) In
#   Zabbix, create your host with the same name (no spaces in the name of
#   the host supported) and create your item with the specified key as a
#   Zabbix Trapper item.  The easiest way to use this output is with the
#   grep filter. Presumably, you only want certain events matching a given
#   pattern to send events to zabbix, so use grep to match and also to add
#   the required fields.   filter {    grep {      type =&gt;
#   "linux-syslog"      match =&gt; [ "@message", "(error|ERROR|CRITICAL)"
#   ]      add_tag =&gt; [ "zabbix-sender" ]      add_field =&gt; [
#   "zabbix_host", "%{source_host}",        "zabbix_item", "item.key"
#   ]   } }  output {   zabbix {     # only process events with this tag
#   tags =&gt; "zabbix-sender"      # specify the hostname or ip of your
#   zabbix server     # (defaults to localhost)     host =&gt; "localhost"
#   # specify the port to connect to (default 10051)     port =&gt;
#   "10051"      # specify the path to zabbix_sender     # (defaults to
#   "/usr/local/bin/zabbix_sender")     zabbix_sender =&gt;
#   "/usr/local/bin/zabbix_sender"   } }
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
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*port*]
#   Value type is number
#   Default value: 10051
#   This variable is optional
#
# [*zabbix_sender*]
#   Value type is path
#   Default value: "/usr/local/bin/zabbix_sender"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/zabbix
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::zabbix (
  $codec         = '',
  $host          = '',
  $port          = '',
  $zabbix_sender = '',
  $instances     = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_zabbix_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/zabbix/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_zabbix_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/zabbix/${name}"

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

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($zabbix_sender != '') {
    if $zabbix_sender =~ /^puppet\:\/\// {

      validate_re($zabbix_sender, '\Apuppet:\/\/')

      $filenameArray_zabbix_sender = split($zabbix_sender, '/')
      $basefilename_zabbix_sender = $filenameArray_zabbix_sender[-1]

      $opt_zabbix_sender = "  zabbix_sender => \"${filesdir}/${basefilename_zabbix_sender}\"\n"

      file { "${filesdir}/${basefilename_zabbix_sender}":
        source  => $zabbix_sender,
        mode    => '0440',
        require => File[$filesdir]
      }
    } else {
      $opt_zabbix_sender = "  zabbix_sender => \"${zabbix_sender}\"\n"
    }
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }


  #### Create the directory where we place the files
  exec { "create_files_dir_output_zabbix_${name}":
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
    require => Exec["create_files_dir_output_zabbix_${name}"],
    notify  => Service[$services]
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n zabbix {\n${opt_codec}${opt_host}${opt_port}${opt_zabbix_sender} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
