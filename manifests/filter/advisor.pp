# == Define: logstash::filter::advisor
#
#   INFORMATION: The filter Advisor is designed for capture and
#   confrontation the events. The events must be grep by a filter first,
#   then it can pull out a copy of it, like clone, whit tags
#   "advisorfirst", this copy is the first occurrence of this event
#   verified in timeadv. After timeadv Advisor will pull out an event
#   tagged "advisorinfo" who will tell you the number of same events
#   verified in time_adv. INFORMATION ABOUT CLASS: For do this job, i used
#   a thread that will sleep time adv. I assume that events coming on
#   advisor are tagged, then i use an array for storing different events.
#   If an events is not present on array, then is the first and if the
#   option is activate then  advisor push out a copy of event. Else if the
#   event is present on array, then is another same event and not the
#   first, let's count it. USAGE: This is an example of logstash config:
#   filter{  advisor {  time_adv =&gt; 1                     #(optional)
#   send_first =&gt; true                #(optional)    } } We analize
#   this: timeadv =&gt; 1 Means the time when the events matched and
#   collected are pushed on outputs with tag "advisorinfo". sendfirst
#   =&gt; true Means you can push out the first events different who came
#   in advisor like clone copy and tagged with "advisorfirst"
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   advisor {     add_field =&gt; [
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
#   syntax. Example:  filter {   advisor {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   advisor {     remove_field =&gt; [
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
#   syntax. Example:  filter {   advisor {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*send_first*]
#   If you want the first different event will be pushed out like a copy
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*time_adv*]
#   If you do not set time_adv the plugin does nothing.
#   Value type is number
#   Default value: 0
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
#  http://logstash.net/docs/1.2.2.dev/filters/advisor
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::advisor (
  $add_field    = '',
  $add_tag      = '',
  $remove_field = '',
  $remove_tag   = '',
  $send_first   = '',
  $time_adv     = '',
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
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_advisor_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/advisor/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_advisor_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/advisor/${name}"

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

  if ($send_first != '') {
    validate_bool($send_first)
    $opt_send_first = "  send_first => ${send_first}\n"
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

  if ($time_adv != '') {
    if ! is_numeric($time_adv) {
      fail("\"${time_adv}\" is not a valid time_adv parameter value")
    } else {
      $opt_time_adv = "  time_adv => ${time_adv}\n"
    }
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n advisor {\n${opt_add_field}${opt_add_tag}${opt_remove_field}${opt_remove_tag}${opt_send_first}${opt_time_adv} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
