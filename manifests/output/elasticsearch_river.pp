# == Define: logstash::output::elasticsearch_river
#
#   This output lets you store logs in elasticsearch. It's similar to the
#   'elasticsearch' output but improves performance by using a queue
#   server, rabbitmq, to send data to elasticsearch.  Upon startup, this
#   output will automatically contact an elasticsearch cluster and
#   configure it to read from the queue to which we write.  You can learn
#   more about elasticseasrch at http://elasticsearch.org More about the
#   elasticsearch rabbitmq river plugin:
#   https://github.com/elasticsearch/elasticsearch-river-rabbitmq/blob/master/README.md
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
# [*debug*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*document_id*]
#   The document ID for the index. Useful for overwriting existing entries
#   in elasticsearch with the same ID.
#   Value type is string
#   Default value: nil
#   This variable is optional
#
# [*durable*]
#   RabbitMQ durability setting. Also used for ElasticSearch setting
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*es_bulk_size*]
#   ElasticSearch river configuration: bulk fetch size
#   Value type is number
#   Default value: 1000
#   This variable is optional
#
# [*es_bulk_timeout_ms*]
#   ElasticSearch river configuration: bulk timeout in milliseconds
#   Value type is number
#   Default value: 100
#   This variable is optional
#
# [*es_host*]
#   The name/address of an ElasticSearch host to use for river creation
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*es_ordered*]
#   ElasticSearch river configuration: is ordered?
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*es_port*]
#   ElasticSearch API port
#   Value type is number
#   Default value: 9200
#   This variable is optional
#
# [*exchange*]
#   RabbitMQ exchange name
#   Value type is string
#   Default value: "elasticsearch"
#   This variable is optional
#
# [*exchange_type*]
#   The exchange type (fanout, topic, direct)
#   Value can be any of: "fanout", "direct", "topic"
#   Default value: "direct"
#   This variable is optional
#
# [*index*]
#   The index to write events to. This can be dynamic using the %{foo}
#   syntax. The default value will partition your indeces by day so you
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
#   Default value: "%{type}"
#   This variable is optional
#
# [*key*]
#   RabbitMQ routing key
#   Value type is string
#   Default value: "elasticsearch"
#   This variable is optional
#
# [*password*]
#   RabbitMQ password
#   Value type is string
#   Default value: "guest"
#   This variable is optional
#
# [*persistent*]
#   RabbitMQ persistence setting
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*queue*]
#   RabbitMQ queue name
#   Value type is string
#   Default value: "elasticsearch"
#   This variable is optional
#
# [*rabbitmq_host*]
#   Hostname of RabbitMQ server
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*rabbitmq_port*]
#   Port of RabbitMQ server
#   Value type is number
#   Default value: 5672
#   This variable is optional
#
# [*user*]
#   RabbitMQ user
#   Value type is string
#   Default value: "guest"
#   This variable is optional
#
# [*vhost*]
#   RabbitMQ vhost
#   Value type is string
#   Default value: "/"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/elasticsearch_river
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::elasticsearch_river (
  $es_host,
  $rabbitmq_host,
  $index              = '',
  $durable            = '',
  $es_bulk_size       = '',
  $es_bulk_timeout_ms = '',
  $codec              = '',
  $es_ordered         = '',
  $es_port            = '',
  $exchange           = '',
  $exchange_type      = '',
  $document_id        = '',
  $index_type         = '',
  $key                = '',
  $password           = '',
  $persistent         = '',
  $queue              = '',
  $debug              = '',
  $rabbitmq_port      = '',
  $user               = '',
  $vhost              = '',
  $instances          = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_elasticsearch_river_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/elasticsearch_river/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_elasticsearch_river_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/elasticsearch_river/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($persistent != '') {
    validate_bool($persistent)
    $opt_persistent = "  persistent => ${persistent}\n"
  }

  if ($es_ordered != '') {
    validate_bool($es_ordered)
    $opt_es_ordered = "  es_ordered => ${es_ordered}\n"
  }

  if ($durable != '') {
    validate_bool($durable)
    $opt_durable = "  durable => ${durable}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($es_port != '') {
    if ! is_numeric($es_port) {
      fail("\"${es_port}\" is not a valid es_port parameter value")
    } else {
      $opt_es_port = "  es_port => ${es_port}\n"
    }
  }

  if ($rabbitmq_port != '') {
    if ! is_numeric($rabbitmq_port) {
      fail("\"${rabbitmq_port}\" is not a valid rabbitmq_port parameter value")
    } else {
      $opt_rabbitmq_port = "  rabbitmq_port => ${rabbitmq_port}\n"
    }
  }

  if ($es_bulk_timeout_ms != '') {
    if ! is_numeric($es_bulk_timeout_ms) {
      fail("\"${es_bulk_timeout_ms}\" is not a valid es_bulk_timeout_ms parameter value")
    } else {
      $opt_es_bulk_timeout_ms = "  es_bulk_timeout_ms => ${es_bulk_timeout_ms}\n"
    }
  }

  if ($es_bulk_size != '') {
    if ! is_numeric($es_bulk_size) {
      fail("\"${es_bulk_size}\" is not a valid es_bulk_size parameter value")
    } else {
      $opt_es_bulk_size = "  es_bulk_size => ${es_bulk_size}\n"
    }
  }

  if ($exchange_type != '') {
    if ! ($exchange_type in ['fanout', 'direct', 'topic']) {
      fail("\"${exchange_type}\" is not a valid exchange_type parameter value")
    } else {
      $opt_exchange_type = "  exchange_type => \"${exchange_type}\"\n"
    }
  }

  if ($rabbitmq_host != '') {
    validate_string($rabbitmq_host)
    $opt_rabbitmq_host = "  rabbitmq_host => \"${rabbitmq_host}\"\n"
  }

  if ($key != '') {
    validate_string($key)
    $opt_key = "  key => \"${key}\"\n"
  }

  if ($password != '') {
    validate_string($password)
    $opt_password = "  password => \"${password}\"\n"
  }

  if ($es_host != '') {
    validate_string($es_host)
    $opt_es_host = "  es_host => \"${es_host}\"\n"
  }

  if ($queue != '') {
    validate_string($queue)
    $opt_queue = "  queue => \"${queue}\"\n"
  }

  if ($index_type != '') {
    validate_string($index_type)
    $opt_index_type = "  index_type => \"${index_type}\"\n"
  }

  if ($exchange != '') {
    validate_string($exchange)
    $opt_exchange = "  exchange => \"${exchange}\"\n"
  }

  if ($document_id != '') {
    validate_string($document_id)
    $opt_document_id = "  document_id => \"${document_id}\"\n"
  }

  if ($user != '') {
    validate_string($user)
    $opt_user = "  user => \"${user}\"\n"
  }

  if ($vhost != '') {
    validate_string($vhost)
    $opt_vhost = "  vhost => \"${vhost}\"\n"
  }

  if ($index != '') {
    validate_string($index)
    $opt_index = "  index => \"${index}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n elasticsearch_river {\n${opt_codec}${opt_debug}${opt_document_id}${opt_durable}${opt_es_bulk_size}${opt_es_bulk_timeout_ms}${opt_es_host}${opt_es_ordered}${opt_es_port}${opt_exchange}${opt_exchange_type}${opt_index}${opt_index_type}${opt_key}${opt_password}${opt_persistent}${opt_queue}${opt_rabbitmq_host}${opt_rabbitmq_port}${opt_user}${opt_vhost} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
