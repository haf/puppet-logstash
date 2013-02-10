# == Define: logstash::output::elasticsearch_http
#
#   This output lets you store logs in elasticsearch.  This plugin uses
#   the HTTP/REST interface to ElasticSearch, which usually lets you use
#   any version of elasticsearch server. It is known to work with
#   elasticsearch %ELASTICSEARCH_VERSION%  You can learn more about
#   elasticsearch at http://elasticsearch.org
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
# [*document_id*]
#   The document ID for the index. Useful for overwriting existing entries
#   in elasticsearch with the same ID.
#   Value type is string
#   Default value: nil
#   This variable is optional
#
# [*flush_size*]
#   Set the number of events to queue up before writing to elasticsearch.
#   Value type is number
#   Default value: 100
#   This variable is optional
#
# [*host*]
#   The hostname or ip address to reach your elasticsearch server.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*idle_flush_time*]
#   The amount of time since last flush before a flush is forced.
#   Value type is number
#   Default value: 1
#   This variable is optional
#
# [*index*]
#   The index to write events to. This can be dynamic using the %{foo}
#   syntax. The default value will partition your indices by day so you
#   can more easily delete old data or only search specific date ranges.
#   Value type is string
#   Default value: "logstash-%{+YYYY.MM.dd}"
#   This variable is optional
#
# [*index_type*]
#   The index type to write events to. Generally you should try to write
#   only similar events to the same 'type'. String expansion '%{foo}'
#   works here.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*port*]
#   The port for ElasticSearch HTTP interface to use.
#   Value type is number
#   Default value: 9200
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
#  http://logstash.net/docs/1.2.2.dev/outputs/elasticsearch_http
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::elasticsearch_http (
  $codec           = '',
  $document_id     = '',
  $flush_size      = '',
  $host            = '',
  $idle_flush_time = '',
  $index           = '',
  $index_type      = '',
  $port            = '',
  $instances       = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_elasticsearch_http_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/elasticsearch_http/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_elasticsearch_http_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/elasticsearch_http/${name}"

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

  if ($idle_flush_time != '') {
    if ! is_numeric($idle_flush_time) {
      fail("\"${idle_flush_time}\" is not a valid idle_flush_time parameter value")
    } else {
      $opt_idle_flush_time = "  idle_flush_time => ${idle_flush_time}\n"
    }
  }

  if ($flush_size != '') {
    if ! is_numeric($flush_size) {
      fail("\"${flush_size}\" is not a valid flush_size parameter value")
    } else {
      $opt_flush_size = "  flush_size => ${flush_size}\n"
    }
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($index_type != '') {
    validate_string($index_type)
    $opt_index_type = "  index_type => \"${index_type}\"\n"
  }

  if ($document_id != '') {
    validate_string($document_id)
    $opt_document_id = "  document_id => \"${document_id}\"\n"
  }

  if ($index != '') {
    validate_string($index)
    $opt_index = "  index => \"${index}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n elasticsearch_http {\n${opt_codec}${opt_document_id}${opt_flush_size}${opt_host}${opt_idle_flush_time}${opt_index}${opt_index_type}${opt_port} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
