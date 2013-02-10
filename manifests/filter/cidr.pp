# == Define: logstash::filter::cidr
#
#   The CIDR filter is for checking IP addresses in events against a list
#   of network blocks that might contain it. Multiple addresses can be
#   checked against multiple networks, any match succeeds. Upon success
#   additional tags and/or fields can be added to the event.
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   cidr {     add_field =&gt; [
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
#   syntax. Example:  filter {   cidr {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*address*]
#   The IP address(es) to check with. Example:  filter {   cidr {
#   add_tag =&gt; [ "testnet" ]     address =&gt; [ "%{src_ip}",
#   "%{dst_ip}" ]     network =&gt; [ "192.0.2.0/24" ]   } }
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*network*]
#   The IP network(s) to check against. Example:  filter {   cidr {
#   add_tag =&gt; [ "linklocal" ]     address =&gt; [ "%{clientip}" ]
#   network =&gt; [ "169.254.0.0/16", "fe80::/64" ]   } }
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   cidr {     remove_field =&gt; [
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
#   syntax. Example:  filter {   cidr {     remove_tag =&gt; [
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
#  http://logstash.net/docs/1.2.2.dev/filters/cidr
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::cidr (
  $add_field    = '',
  $add_tag      = '',
  $address      = '',
  $network      = '',
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
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_cidr_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/cidr/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_cidr_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/cidr/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($add_tag != '') {
    validate_array($add_tag)
    $arr_add_tag = join($add_tag, '\', \'')
    $opt_add_tag = "  add_tag => ['${arr_add_tag}']\n"
  }

  if ($address != '') {
    validate_array($address)
    $arr_address = join($address, '\', \'')
    $opt_address = "  address => ['${arr_address}']\n"
  }

  if ($network != '') {
    validate_array($network)
    $arr_network = join($network, '\', \'')
    $opt_network = "  network => ['${arr_network}']\n"
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
    content => "filter {\n cidr {\n${opt_add_field}${opt_add_tag}${opt_address}${opt_network}${opt_remove_field}${opt_remove_tag} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
