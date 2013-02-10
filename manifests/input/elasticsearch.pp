# == Define: logstash::input::elasticsearch
#
#   Read from elasticsearch.  This is useful for replay testing logs,
#   reindexing, etc.  Example:  input {   # Read all documents from
#   elasticsearch matching the given query   elasticsearch {     host
#   =&gt; "localhost"     query =&gt; "ERROR"   } }   TODO(sissel):
#   configurable scroll timeout TODO(sissel): Option to keep the index,
#   type, and doc id so we can do reindexing?
#
#
# === Parameters
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   The address of your elasticsearch server
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*index*]
#   The index to search
#   Value type is string
#   Default value: "logstash-*"
#   This variable is optional
#
# [*port*]
#   The http port of your elasticsearch server's REST interface
#   Value type is number
#   Default value: 9200
#   This variable is optional
#
# [*query*]
#   The query to use
#   Value type is string
#   Default value: "*"
#   This variable is optional
#
# [*scan*]
#   Enable the scan search_type. This will disable sorting but increase
#   speed and performance.
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*scroll*]
#   this parameter controls the keep alive time of the scrolling request
#   and initiates the scrolling process. The timeout applies per round
#   trip (i.e. between the previous scan scroll request, to the next).
#   Value type is string
#   Default value: "1m"
#   This variable is optional
#
# [*size*]
#   This allows you to set the number of items you get back per scroll
#   Value type is number
#   Default value: 1000
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*type*]
#   Add a 'type' field to all events handled by this input.  Types are
#   used mainly for filter activation.  If you create an input with type
#   "foobar", then only filters which also have type "foobar" will act on
#   them.  The type is also stored as part of the event itself, so you can
#   also use the type to search for in the web interface.  If you try to
#   set a type on an event that already has one (for example when you send
#   an event from a shipper to an indexer) then a new input will not
#   override the existing type. A type set at the shipper stays with that
#   event for its life even when sent to another LogStash server.
#   Value type is string
#   Default value: None
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
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.2.2.dev/inputs/elasticsearch
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::elasticsearch (
  $host,
  $port           = '',
  $codec          = '',
  $debug          = '',
  $add_field      = '',
  $index          = '',
  $query          = '',
  $scan           = '',
  $scroll         = '',
  $size           = '',
  $tags           = '',
  $type           = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_elasticsearch_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/elasticsearch/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_elasticsearch_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/elasticsearch/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($scan != '') {
    validate_bool($scan)
    $opt_scan = "  scan => ${scan}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($size != '') {
    if ! is_numeric($size) {
      fail("\"${size}\" is not a valid size parameter value")
    } else {
      $opt_size = "  size => ${size}\n"
    }
  }

  if ($scroll != '') {
    validate_string($scroll)
    $opt_scroll = "  scroll => \"${scroll}\"\n"
  }

  if ($query != '') {
    validate_string($query)
    $opt_query = "  query => \"${query}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($index != '') {
    validate_string($index)
    $opt_index = "  index => \"${index}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n elasticsearch {\n${opt_add_field}${opt_codec}${opt_debug}${opt_host}${opt_index}${opt_port}${opt_query}${opt_scan}${opt_scroll}${opt_size}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
