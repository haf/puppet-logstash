# == Define: logstash::input::sqlite
#
#   Read rows from an sqlite database.  This is most useful in cases where
#   you are logging directly to a table. Any tables being watched must
#   have an 'id' column that is monotonically increasing.  All tables are
#   read by default except: * ones matching 'sqlite%' - these are
#   internal/adminstrative tables for sqlite * 'sincetable' - this is used
#   by this plugin to track state.  Example  % sqlite /tmp/example.db
#   sqlite&gt; CREATE TABLE weblogs (     id INTEGER PRIMARY KEY
#   AUTOINCREMENT,     ip STRING,     request STRING,     response
#   INTEGER); sqlite&gt; INSERT INTO weblogs (ip, request, response)
#   VALUES ("1.2.3.4", "/index.html", 200);   Then with this logstash
#   config:  input {   sqlite {     path =&gt; "/tmp/example.db"     type
#   =&gt; weblogs   } } output {   stdout {     debug =&gt; true   } }
#   Sample output:  {   "@source"      =&gt; "sqlite://sadness/tmp/x.db",
#   "@tags"        =&gt; [],   "@fields"      =&gt; {     "ip"       =&gt;
#   "1.2.3.4",     "request"  =&gt; "/index.html",     "response" =&gt;
#   200   },   "@timestamp"   =&gt; "2013-05-29T06:16:30.850Z",
#   "@source_host" =&gt; "sadness",   "@source_path" =&gt; "/tmp/x.db",
#   "@message"     =&gt; "",   "@type"        =&gt; "foo" }
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
# [*batch*]
#   How many rows to fetch at a time from each SELECT call.
#   Value type is number
#   Default value: 5
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
# [*exclude_tables*]
#   Any tables to exclude by name. By default all tables are followed.
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*path*]
#   The path to the sqlite database file.
#   Value type is string
#   Default value: None
#   This variable is required
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
#  http://logstash.net/docs/1.2.2.dev/inputs/sqlite
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::sqlite (
  $path,
  $codec          = '',
  $debug          = '',
  $exclude_tables = '',
  $batch          = '',
  $add_field      = '',
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
    $conffiles    = suffix($confdirstart, "/config/input_sqlite_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/sqlite/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_sqlite_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/sqlite/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($exclude_tables != '') {
    validate_array($exclude_tables)
    $arr_exclude_tables = join($exclude_tables, '\', \'')
    $opt_exclude_tables = "  exclude_tables => ['${arr_exclude_tables}']\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
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

  if ($batch != '') {
    if ! is_numeric($batch) {
      fail("\"${batch}\" is not a valid batch parameter value")
    } else {
      $opt_batch = "  batch => ${batch}\n"
    }
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($path != '') {
    validate_string($path)
    $opt_path = "  path => \"${path}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n sqlite {\n${opt_add_field}${opt_batch}${opt_codec}${opt_debug}${opt_exclude_tables}${opt_path}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
