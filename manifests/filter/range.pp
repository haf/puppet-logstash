# == Define: logstash::filter::range
#
#   This filter is used to check that certain fields are within expected
#   size/length ranges. Supported types are numbers and strings. Numbers
#   are checked to be within numeric value range. Strings are checked to
#   be within string length range. More than one range can be specified
#   for same fieldname, actions will be applied incrementally. Then field
#   value is with in a specified range and action will be taken supported
#   actions are drop event add tag or add field with specified value.
#   Example usecases are for histogram like tagging of events or for
#   finding anomaly values in fields or too big events that should be
#   dropped.
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   range {     add_field =&gt; [
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
#   syntax. Example:  filter {   range {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*negate*]
#   Negate the range match logic, events should be outsize of the
#   specificed range to match.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*ranges*]
#   An array of field, min, max ,action tuples. Example:  filter {
#   range {     ranges =&gt; [ "message", 0, 10, "tag:short",
#   "message", 11, 100, "tag:medium",                 "message", 101,
#   1000, "tag:long",                 "message", 1001, 1e1000, "drop",
#   "duration", 0, 100, "field:latency:fast",                 "duration",
#   101, 200, "field:latency:normal",                 "duration", 201,
#   1000, "field:latency:slow",                 "duration", 1001, 1e1000,
#   "field:latency:outlier"                  "requests", 0, 10,
#   "tag:to_few_%{host}_requests" ]   } }   Supported actions are drop tag
#   or field with specified value. Added tag names and field names and
#   field values can have %{dynamic} values.  TODO(piavlo): The action
#   syntax is ugly at the moment due to logstash grammar limitations -
#   arrays grammar should support TODO(piavlo): simple not nested hashses
#   as values in addition to numaric and string values to prettify the
#   syntax.
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   range {     remove_field =&gt; [
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
#   syntax. Example:  filter {   range {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
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
#  http://logstash.net/docs/1.2.2.dev/filters/range
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::range (
  $add_field    = '',
  $add_tag      = '',
  $negate       = '',
  $ranges       = '',
  $remove_field = '',
  $remove_tag   = '',
  $order        = 10,
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_range_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/range/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_range_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/range/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($add_tag != '') {
    validate_array($add_tag)
    $arr_add_tag = join($add_tag, '\', \'')
    $opt_add_tag = "  add_tag => ['${arr_add_tag}']\n"
  }

  if ($ranges != '') {
    validate_array($ranges)
    $arr_ranges = join($ranges, '\', \'')
    $opt_ranges = "  ranges => ['${arr_ranges}']\n"
  }

  if ($remove_tag != '') {
    validate_array($remove_tag)
    $arr_remove_tag = join($remove_tag, '\', \'')
    $opt_remove_tag = "  remove_tag => ['${arr_remove_tag}']\n"
  }

  if ($remove_field != '') {
    validate_array($remove_field)
    $arr_remove_field = join($remove_field, '\', \'')
    $opt_remove_field = "  remove_field => ['${arr_remove_field}']\n"
  }

  if ($negate != '') {
    validate_bool($negate)
    $opt_negate = "  negate => ${negate}\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($order != '') {
    if ! is_numeric($order) {
      fail("\"${order}\" is not a valid order parameter value")
    }
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n range {\n${opt_add_field}${opt_add_tag}${opt_negate}${opt_ranges}${opt_remove_field}${opt_remove_tag} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
