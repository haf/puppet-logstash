# == Define: logstash::output::gemfire
#
#   Push events to a GemFire region.  GemFire is an object database.  To
#   use this plugin you need to add gemfire.jar to your CLASSPATH; using
#   format=json requires jackson.jar too.  Note: this plugin has only been
#   tested with GemFire 7.0.
#
#
# === Parameters
#
# [*cache_name*]
#   Your client cache name
#   Value type is string
#   Default value: "logstash"
#   This variable is optional
#
# [*cache_xml_file*]
#   The path to a GemFire client cache XML file.  Example:
#   &lt;client-cache&gt;    &lt;pool name="client-pool"&gt;
#   &lt;locator host="localhost" port="31331"/&gt;    &lt;/pool&gt;
#   &lt;region name="Logstash"&gt;        &lt;region-attributes
#   refid="CACHING_PROXY" pool-name="client-pool" &gt;
#   &lt;/region-attributes&gt;    &lt;/region&gt;  &lt;/client-cache&gt;
#   Value type is string
#   Default value: nil
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*key_format*]
#   A sprintf format to use when building keys
#   Value type is string
#   Default value: "%{host}-%{@timestamp}"
#   This variable is optional
#
# [*region_name*]
#   The region name
#   Value type is string
#   Default value: "Logstash"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/gemfire
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::gemfire (
  $cache_name     = '',
  $cache_xml_file = '',
  $codec          = '',
  $key_format     = '',
  $region_name    = '',
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_gemfire_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/gemfire/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_gemfire_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/gemfire/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($key_format != '') {
    validate_string($key_format)
    $opt_key_format = "  key_format => \"${key_format}\"\n"
  }

  if ($region_name != '') {
    validate_string($region_name)
    $opt_region_name = "  region_name => \"${region_name}\"\n"
  }

  if ($cache_xml_file != '') {
    validate_string($cache_xml_file)
    $opt_cache_xml_file = "  cache_xml_file => \"${cache_xml_file}\"\n"
  }

  if ($cache_name != '') {
    validate_string($cache_name)
    $opt_cache_name = "  cache_name => \"${cache_name}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n gemfire {\n${opt_cache_name}${opt_cache_xml_file}${opt_codec}${opt_key_format}${opt_region_name} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
