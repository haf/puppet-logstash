# == Define: logstash::output::mongodb
#
#
#
# === Parameters
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*collection*]
#   The collection to use. This value can use %{foo} values to dynamically
#   select a collection based on data in the event.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*database*]
#   The database to use
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*generateId*]
#   If true, a id field will be added to the document before insertion.
#   The id field will use the timestamp of the event and overwrite an
#   existing _id field in the event.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*isodate*]
#   If true, store the @timestamp field in mongodb as an ISODate type
#   instead of an ISO8601 string.  For more information about this, see
#   http://www.mongodb.org/display/DOCS/Dates
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*retry_delay*]
#   Number of seconds to wait after failure before retrying
#   Value type is number
#   Default value: 3
#   This variable is optional
#
# [*uri*]
#   a MongoDB URI to connect to See
#   http://docs.mongodb.org/manual/reference/connection-string/
#   Value type is string
#   Default value: None
#   This variable is required
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
#  http://logstash.net/docs/1.2.2.dev/outputs/mongodb
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::mongodb (
  $collection,
  $uri,
  $database,
  $isodate      = '',
  $generateId   = '',
  $retry_delay  = '',
  $codec        = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_mongodb_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/mongodb/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_mongodb_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/mongodb/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($generateId != '') {
    validate_bool($generateId)
    $opt_generateId = "  generateId => ${generateId}\n"
  }

  if ($isodate != '') {
    validate_bool($isodate)
    $opt_isodate = "  isodate => ${isodate}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($retry_delay != '') {
    if ! is_numeric($retry_delay) {
      fail("\"${retry_delay}\" is not a valid retry_delay parameter value")
    } else {
      $opt_retry_delay = "  retry_delay => ${retry_delay}\n"
    }
  }

  if ($collection != '') {
    validate_string($collection)
    $opt_collection = "  collection => \"${collection}\"\n"
  }

  if ($uri != '') {
    validate_string($uri)
    $opt_uri = "  uri => \"${uri}\"\n"
  }

  if ($database != '') {
    validate_string($database)
    $opt_database = "  database => \"${database}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n mongodb {\n${opt_codec}${opt_collection}${opt_database}${opt_generateId}${opt_isodate}${opt_retry_delay}${opt_uri} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
