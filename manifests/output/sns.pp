# == Define: logstash::output::sns
#
#   SNS output.  Send events to Amazon's Simple Notification Service, a
#   hosted pub/sub framework.  It supports subscribers of type email,
#   HTTP/S, SMS, and SQS.  For further documentation about the service
#   see:    http://docs.amazonwebservices.com/sns/latest/api/  This plugin
#   looks for the following fields on events it receives:  sns - If no ARN
#   is found in the configuration file, this will be used as the ARN to
#   publish. snssubject - The subject line that should be used. Optional.
#   The "%{host}" will be used if not present and truncated at
#   MAXSUBJECTSIZEIN_CHARACTERS. snsmessage - The message that should be
#   sent. Optional. The event serialzed as JSON will be used if not
#   present and with the @message truncated so that the length of the JSON
#   fits in MAXMESSAGESIZEIN_BYTES.
#
#
# === Parameters
#
# [*access_key_id*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*arn*]
#   SNS topic ARN.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*aws_credentials_file*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*format*]
#   Message format.  Defaults to plain text.
#   Value can be any of: "json", "plain"
#   Default value: "plain"
#   This variable is optional
#
# [*publish_boot_message_arn*]
#   When an ARN for an SNS topic is specified here, the message "Logstash
#   successfully booted" will be sent to it when this plugin is
#   registered.  Example:
#   arn:aws:sns:us-east-1:770975001275:logstash-testing
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*region*]
#   Value can be any of: "us-east-1", "us-west-1", "us-west-2",
#   "eu-west-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1",
#   "sa-east-1", "us-gov-west-1"
#   Default value: "us-east-1"
#   This variable is optional
#
# [*secret_access_key*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*use_ssl*]
#   Value type is boolean
#   Default value: true
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
#  http://logstash.net/docs/1.2.2.dev/outputs/sns
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::sns (
  $access_key_id            = '',
  $arn                      = '',
  $aws_credentials_file     = '',
  $codec                    = '',
  $format                   = '',
  $publish_boot_message_arn = '',
  $region                   = '',
  $secret_access_key        = '',
  $use_ssl                  = '',
  $instances                = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_sns_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/sns/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_sns_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/sns/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($use_ssl != '') {
    validate_bool($use_ssl)
    $opt_use_ssl = "  use_ssl => ${use_ssl}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($format != '') {
    if ! ($format in ['json', 'plain']) {
      fail("\"${format}\" is not a valid format parameter value")
    } else {
      $opt_format = "  format => \"${format}\"\n"
    }
  }

  if ($region != '') {
    if ! ($region in ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'sa-east-1', 'us-gov-west-1']) {
      fail("\"${region}\" is not a valid region parameter value")
    } else {
      $opt_region = "  region => \"${region}\"\n"
    }
  }

  if ($publish_boot_message_arn != '') {
    validate_string($publish_boot_message_arn)
    $opt_publish_boot_message_arn = "  publish_boot_message_arn => \"${publish_boot_message_arn}\"\n"
  }

  if ($secret_access_key != '') {
    validate_string($secret_access_key)
    $opt_secret_access_key = "  secret_access_key => \"${secret_access_key}\"\n"
  }

  if ($aws_credentials_file != '') {
    validate_string($aws_credentials_file)
    $opt_aws_credentials_file = "  aws_credentials_file => \"${aws_credentials_file}\"\n"
  }

  if ($arn != '') {
    validate_string($arn)
    $opt_arn = "  arn => \"${arn}\"\n"
  }

  if ($access_key_id != '') {
    validate_string($access_key_id)
    $opt_access_key_id = "  access_key_id => \"${access_key_id}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n sns {\n${opt_access_key_id}${opt_arn}${opt_aws_credentials_file}${opt_codec}${opt_format}${opt_publish_boot_message_arn}${opt_region}${opt_secret_access_key}${opt_use_ssl} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
