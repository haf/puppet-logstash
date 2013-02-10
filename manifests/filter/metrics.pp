# == Define: logstash::filter::metrics
#
#   The metrics filter is useful for aggregating metrics.  For example, if
#   you have a field 'response' that is a http response code, and you want
#   to count each kind of response, you can do this:  filter {   metrics {
#   meter =&gt; [ "http.%{response}" ]     add_tag =&gt; "metric"   } }
#   Metrics are flushed every 5 seconds by default or according to
#   'flush_interval'. Metrics appear as new events in the event stream and
#   go through any filters that occur after as well as outputs.  In
#   general, you will want to add a tag to your metrics and have an output
#   explicitly look for that tag.  The event that is flushed will include
#   every 'meter' and 'timer' metric in the following way:  'meter' values
#   For a meter =&gt; "something" you will receive the following fields:
#   "thing.count" - the total count of events "thing.rate_1m" - the
#   1-minute rate (sliding) "thing.rate_5m" - the 5-minute rate (sliding)
#   "thing.rate_15m" - the 15-minute rate (sliding) 'timer' values  For a
#   timer =&gt; [ "thing", "%{duration}" ] you will receive the following
#   fields:  "thing.count" - the total count of events "thing.rate_1m" -
#   the 1-minute rate of events (sliding) "thing.rate_5m" - the 5-minute
#   rate of events (sliding) "thing.rate_15m" - the 15-minute rate of
#   events (sliding) "thing.min" - the minimum value seen for this metric
#   "thing.max" - the maximum value seen for this metric "thing.stddev" -
#   the standard deviation for this metric "thing.mean" - the mean for
#   this metric Example: computing event rate  For a simple example, let's
#   track how many events per second are running through logstash:  input
#   {   generator {     type =&gt; "generated"   } }  filter {   metrics {
#   type =&gt; "generated"     meter =&gt; "events"     add_tag =&gt;
#   "metric"   } }  output {   stdout {     # only emit events with the
#   'metric' tag     tags =&gt; "metric"     message =&gt; "rate:
#   %{events.rate_1m}"   } }   Running the above:  % java -jar
#   logstash.jar agent -f example.conf rate: 23721.983566819246 rate:
#   24811.395722536377 rate: 25875.892745934525 rate: 26836.42375967113
#   We see the output includes our 'events' 1-minute rate.  In the real
#   world, you would emit this to graphite or another metrics store, like
#   so:  output {   graphite {     metrics =&gt; [ "events.rate_1m",
#   "%{events.rate_1m}" ]   } }
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   metrics {     add_field =&gt; [
#   "foo_%{somefield}", "Hello world, from %{host}" ]   } }   If the event
#   has field "somefield" == "hello" this filter, on success, would add
#   field "foo_hello" if it is present, with the value above and the
#   %{host} piece replaced with that value from the event.
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*add_tag*]
#   If this filter is successful, add arbitrary tags to the event. Tags
#   can be dynamic and include parts of the event using the %{field}
#   syntax. Example:  filter {   metrics {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*clear_interval*]
#   The clear interval, when all counter are reset.  If set to -1, the
#   default value, the metrics will never be cleared. Otherwise, should be
#   a multiple of 5s.
#   Value type is number
#   Default value: -1
#   This variable is optional
#
# [*flush_interval*]
#   The flush interval, when the metrics event is created. Must be a
#   multiple of 5s.
#   Value type is number
#   Default value: 5
#   This variable is optional
#
# [*ignore_older_than*]
#   Don't track events that have @timestamp older than some number of
#   seconds.  This is useful if you want to only include events that are
#   near real-time in your metrics.  Example, to only count events that
#   are within 10 seconds of real-time, you would do this:  filter {
#   metrics {     meter =&gt; [ "hits" ]     ignore_older_than =&gt; 10
#   } }
#   Value type is number
#   Default value: 0
#   This variable is optional
#
# [*meter*]
#   syntax: meter =&gt; [ "name of metric", "name of metric" ]
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   metrics {     remove_field =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the field with name
#   "foo_hello" if it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_tag*]
#   If this filter is successful, remove arbitrary tags from the event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   syntax. Example:  filter {   metrics {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*timer*]
#   syntax: timer =&gt; [ "name of metric", "%{time_value}" ]
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*order*]
#   The order variable decides in which sequence the filters are loaded.
#   Value type is number
#   Default value: 10
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
#  Extra information about this filter can be found at:
#  http://logstash.net/docs/1.2.2.dev/filters/metrics
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::metrics (
  $add_field         = '',
  $add_tag           = '',
  $clear_interval    = '',
  $flush_interval    = '',
  $ignore_older_than = '',
  $meter             = '',
  $remove_field      = '',
  $remove_tag        = '',
  $timer             = '',
  $order             = 10,
  $instances         = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_metrics_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/metrics/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_metrics_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/metrics/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($add_tag != '') {
    validate_array($add_tag)
    $arr_add_tag = join($add_tag, '\', \'')
    $opt_add_tag = "  add_tag => ['${arr_add_tag}']\n"
  }

  if ($remove_tag != '') {
    validate_array($remove_tag)
    $arr_remove_tag = join($remove_tag, '\', \'')
    $opt_remove_tag = "  remove_tag => ['${arr_remove_tag}']\n"
  }

  if ($meter != '') {
    validate_array($meter)
    $arr_meter = join($meter, '\', \'')
    $opt_meter = "  meter => ['${arr_meter}']\n"
  }

  if ($remove_field != '') {
    validate_array($remove_field)
    $arr_remove_field = join($remove_field, '\', \'')
    $opt_remove_field = "  remove_field => ['${arr_remove_field}']\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($timer != '') {
    validate_hash($timer)
    $var_timer = $timer
    $arr_timer = inline_template('<%= "["+@var_timer.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_timer = "  timer => ${arr_timer}\n"
  }

  if ($clear_interval != '') {
    if ! is_numeric($clear_interval) {
      fail("\"${clear_interval}\" is not a valid clear_interval parameter value")
    } else {
      $opt_clear_interval = "  clear_interval => ${clear_interval}\n"
    }
  }

  if ($flush_interval != '') {
    if ! is_numeric($flush_interval) {
      fail("\"${flush_interval}\" is not a valid flush_interval parameter value")
    } else {
      $opt_flush_interval = "  flush_interval => ${flush_interval}\n"
    }
  }

  if ($order != '') {
    if ! is_numeric($order) {
      fail("\"${order}\" is not a valid order parameter value")
    }
  }

  if ($ignore_older_than != '') {
    if ! is_numeric($ignore_older_than) {
      fail("\"${ignore_older_than}\" is not a valid ignore_older_than parameter value")
    } else {
      $opt_ignore_older_than = "  ignore_older_than => ${ignore_older_than}\n"
    }
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n metrics {\n${opt_add_field}${opt_add_tag}${opt_clear_interval}${opt_flush_interval}${opt_ignore_older_than}${opt_meter}${opt_remove_field}${opt_remove_tag}${opt_timer} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
