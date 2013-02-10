# == Define: logstash::filter::sort
#
#   The sort filter is for sorting a amount of events or a period of
#   events by timestamp.  The original goal of this filter was to merge
#   the logs from different sources by the time of log, for example, in
#   real-time log collection, logs can be sorted by amount of 3000 logs or
#   can be sorted in 30 seconds.  The config looks like this:  filter {
#   sort {     sortSize =&gt; 3000     sortInterval =&gt; "30s"     sortBy
#   =&gt; "asce"   } }
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   sort {     add_field =&gt; [
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
#   syntax. Example:  filter {   sort {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   sort {     remove_field =&gt; [
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
#   syntax. Example:  filter {   sort {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*sortBy*]
#   The 'sortBy' can only be "asce" or "desc" (defaults asce), sorted by
#   timestamp asce or desc.
#   Value can be any of: "asce", "desc"
#   Default value: "asce"
#   This variable is optional
#
# [*sortInterval*]
#   The 'sortInterval' is the time window which how long the logs should
#   be sorted. (default 1m)
#   Value type is string
#   Default value: "1m"
#   This variable is optional
#
# [*sortSize*]
#   The 'sortSize' is the window size which how many logs should be
#   sorted.(default 1000)
#   Value type is number
#   Default value: 1000
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
#  http://logstash.net/docs/1.2.2.dev/filters/sort
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::sort (
  $add_field    = '',
  $add_tag      = '',
  $remove_field = '',
  $remove_tag   = '',
  $sortBy       = '',
  $sortInterval = '',
  $sortSize     = '',
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
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_sort_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/sort/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_sort_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/sort/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($add_tag != '') {
    validate_array($add_tag)
    $arr_add_tag = join($add_tag, '\', \'')
    $opt_add_tag = "  add_tag => ['${arr_add_tag}']\n"
  }

  if ($remove_field != '') {
    validate_array($remove_field)
    $arr_remove_field = join($remove_field, '\', \'')
    $opt_remove_field = "  remove_field => ['${arr_remove_field}']\n"
  }

  if ($remove_tag != '') {
    validate_array($remove_tag)
    $arr_remove_tag = join($remove_tag, '\', \'')
    $opt_remove_tag = "  remove_tag => ['${arr_remove_tag}']\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($sortSize != '') {
    if ! is_numeric($sortSize) {
      fail("\"${sortSize}\" is not a valid sortSize parameter value")
    } else {
      $opt_sortSize = "  sortSize => ${sortSize}\n"
    }
  }

  if ($order != '') {
    if ! is_numeric($order) {
      fail("\"${order}\" is not a valid order parameter value")
    }
  }

  if ($sortBy != '') {
    if ! ($sortBy in ['asce', 'desc']) {
      fail("\"${sortBy}\" is not a valid sortBy parameter value")
    } else {
      $opt_sortBy = "  sortBy => \"${sortBy}\"\n"
    }
  }

  if ($sortInterval != '') {
    validate_string($sortInterval)
    $opt_sortInterval = "  sortInterval => \"${sortInterval}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n sort {\n${opt_add_field}${opt_add_tag}${opt_remove_field}${opt_remove_tag}${opt_sortBy}${opt_sortInterval}${opt_sortSize} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
