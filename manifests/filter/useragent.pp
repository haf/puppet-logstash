# == Define: logstash::filter::useragent
#
#   Parse user agent strings into structured data based on BrowserScope
#   data  UserAgent filter, adds information about user agent like family,
#   operating system, version, and device  Logstash releases ship with the
#   regexes.yaml database made available from ua-parser with an Apache 2.0
#   license. For more details on ua-parser, see
#   https://github.com/tobie/ua-parser/.
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   useragent {     add_field =&gt; [
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
#   syntax. Example:  filter {   useragent {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*prefix*]
#   A string to prepend to all of the extracted keys
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*regexes*]
#   regexes.yaml file to use  If not specified, this will default to the
#   regexes.yaml that ships with logstash.  You can find the latest
#   version of this here:
#   https://github.com/tobie/ua-parser/blob/master/regexes.yaml
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   useragent {     remove_field =&gt; [
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
#   syntax. Example:  filter {   useragent {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*source*]
#   The field containing the user agent string. If this field is an array,
#   only the first value will be used.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*target*]
#   The name of the field to assign user agent data into.  If not
#   specified user agent data will be stored in the root of the event.
#   Value type is string
#   Default value: None
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
#  http://logstash.net/docs/1.2.2.dev/filters/useragent
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::useragent (
  $source,
  $remove_tag   = '',
  $prefix       = '',
  $regexes      = '',
  $remove_field = '',
  $add_tag      = '',
  $add_field    = '',
  $target       = '',
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
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_useragent_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/useragent/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_useragent_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/useragent/${name}"

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

  if ($order != '') {
    if ! is_numeric($order) {
      fail("\"${order}\" is not a valid order parameter value")
    }
  }

  if ($target != '') {
    validate_string($target)
    $opt_target = "  target => \"${target}\"\n"
  }

  if ($prefix != '') {
    validate_string($prefix)
    $opt_prefix = "  prefix => \"${prefix}\"\n"
  }

  if ($source != '') {
    validate_string($source)
    $opt_source = "  source => \"${source}\"\n"
  }

  if ($regexes != '') {
    validate_string($regexes)
    $opt_regexes = "  regexes => \"${regexes}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n useragent {\n${opt_add_field}${opt_add_tag}${opt_prefix}${opt_regexes}${opt_remove_field}${opt_remove_tag}${opt_source}${opt_target} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
