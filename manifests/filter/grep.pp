# == Define: logstash::filter::grep
#
#   Grep filter. Useful for dropping events you don't want to pass, or
#   adding tags or fields to events that match.  Events not matched are
#   dropped. If 'negate' is set to true (defaults false), then matching
#   events are dropped.
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   grep {     add_field =&gt; [
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
#   syntax. Example:  filter {   grep {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*drop*]
#   Drop events that don't match  If this is set to false, no events will
#   be dropped at all. Rather, the requested tags and fields will be added
#   to matching events, and non-matching events will be passed through
#   unchanged.
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*ignore_case*]
#   Use case-insensitive matching. Similar to 'grep -i'  If enabled,
#   ignore case distinctions in the patterns.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*match*]
#   A hash of matches of field =&gt; regexp.  If multiple matches are
#   specified, all must match for the grep to be considered successful.
#   Normal regular expressions are supported here.  For example:  filter {
#   grep {     match =&gt; [ "message", "hello world" ]   } }   The above
#   will drop all events with a message not matching "hello world" as a
#   regular expression.
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*negate*]
#   Negate the match. Similar to 'grep -v'  If this is set to true, then
#   any positive matches will result in the event being cancelled and
#   dropped. Non-matching will be allowed through.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   grep {     remove_field =&gt; [
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
#   syntax. Example:  filter {   grep {     remove_tag =&gt; [
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
#  http://logstash.net/docs/1.2.2.dev/filters/grep
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::grep (
  $add_field    = '',
  $add_tag      = '',
  $drop         = '',
  $ignore_case  = '',
  $match        = '',
  $negate       = '',
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
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_grep_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/grep/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_grep_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/grep/${name}"

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

  if ($remove_field != '') {
    validate_array($remove_field)
    $arr_remove_field = join($remove_field, '\', \'')
    $opt_remove_field = "  remove_field => ['${arr_remove_field}']\n"
  }

  if ($drop != '') {
    validate_bool($drop)
    $opt_drop = "  drop => ${drop}\n"
  }

  if ($ignore_case != '') {
    validate_bool($ignore_case)
    $opt_ignore_case = "  ignore_case => ${ignore_case}\n"
  }

  if ($negate != '') {
    validate_bool($negate)
    $opt_negate = "  negate => ${negate}\n"
  }

  if ($match != '') {
    validate_hash($match)
    $var_match = $match
    $arr_match = inline_template('<%= "["+@var_match.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_match = "  match => ${arr_match}\n"
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
    content => "filter {\n grep {\n${opt_add_field}${opt_add_tag}${opt_drop}${opt_ignore_case}${opt_match}${opt_negate}${opt_remove_field}${opt_remove_tag} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
