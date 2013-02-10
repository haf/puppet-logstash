# == Define: logstash::input::sqs
#
#   Pull events from an Amazon Web Services Simple Queue Service (SQS)
#   queue.  SQS is a simple, scalable queue system that is part of the
#   Amazon Web Services suite of tools.  Although SQS is similar to other
#   queuing systems like AMQP, it uses a custom API and requires that you
#   have an AWS account. See http://aws.amazon.com/sqs/ for more details
#   on how SQS works, what the pricing schedule looks like and how to
#   setup a queue.  To use this plugin, you must:  Have an AWS account
#   Setup an SQS queue Create an identify that has access to consume
#   messages from the queue. The "consumer" identity must have the
#   following permissions on the queue:  sqs:ChangeMessageVisibility
#   sqs:ChangeMessageVisibilityBatch sqs:DeleteMessage
#   sqs:DeleteMessageBatch sqs:GetQueueAttributes sqs:GetQueueUrl
#   sqs:ListQueues sqs:ReceiveMessage Typically, you should setup an IAM
#   policy, create a user and apply the IAM policy to the user. A sample
#   policy is as follows:  {   "Statement": [     {       "Action": [
#   "sqs:ChangeMessageVisibility",
#   "sqs:ChangeMessageVisibilityBatch",         "sqs:GetQueueAttributes",
#   "sqs:GetQueueUrl",         "sqs:ListQueues",
#   "sqs:SendMessage",         "sqs:SendMessageBatch"       ],
#   "Effect": "Allow",       "Resource": [
#   "arn:aws:sqs:us-east-1:123456789012:Logstash"       ]     }   ] }
#   See http://aws.amazon.com/iam/ for more details on setting up AWS
#   identities.
#
#
# === Parameters
#
# [*access_key_id*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*aws_credentials_file*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*id_field*]
#   Name of the event field in which to store the SQS message ID
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*md5_field*]
#   Name of the event field in which to store the SQS message MD5 checksum
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*queue*]
#   Name of the SQS Queue name to pull messages from. Note that this is
#   just the name of the queue, not the URL or ARN.
#   Value type is string
#   Default value: None
#   This variable is required
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
# [*sent_timestamp_field*]
#   Name of the event field in which to store the  SQS message Sent
#   Timestamp
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
#   This variable is optional
#
# [*threads*]
#   Set this to the number of threads you want this input to spawn. This
#   is the same as declaring the input multiple times
#   Value type is number
#   Default value: 1
#   This variable is optional
#
# [*type*]
#   Add a 'type' field to all events handled by this input.  Types are
#   used mainly for filter activation.  If you create an input with type
#   "foobar", then only filters which also have type "foobar" will act on
#   them.  The type is also stored as part of the event itself, so you can
#   also use the type to search for in the web interface.  If you try to
#   set a type on an event that already has one (for example when you send
#   an event from a shipper to an indexer) then a new input will not
#   override the existing type. A type set at the shipper stays with that
#   event for its life even when sent to another LogStash server.
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
#  Extra information about this input can be found at:
#  http://logstash.net/docs/1.2.2.dev/inputs/sqs
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::sqs (
  $queue,
  $aws_credentials_file = '',
  $codec                = '',
  $debug                = '',
  $id_field             = '',
  $md5_field            = '',
  $add_field            = '',
  $access_key_id        = '',
  $region               = '',
  $secret_access_key    = '',
  $sent_timestamp_field = '',
  $tags                 = '',
  $threads              = '',
  $type                 = '',
  $use_ssl              = '',
  $instances            = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_sqs_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/sqs/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_sqs_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/sqs/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($use_ssl != '') {
    validate_bool($use_ssl)
    $opt_use_ssl = "  use_ssl => ${use_ssl}\n"
  }

  if ($debug != '') {
    validate_bool($debug)
    $opt_debug = "  debug => ${debug}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($threads != '') {
    if ! is_numeric($threads) {
      fail("\"${threads}\" is not a valid threads parameter value")
    } else {
      $opt_threads = "  threads => ${threads}\n"
    }
  }

  if ($region != '') {
    if ! ($region in ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'sa-east-1', 'us-gov-west-1']) {
      fail("\"${region}\" is not a valid region parameter value")
    } else {
      $opt_region = "  region => \"${region}\"\n"
    }
  }

  if ($queue != '') {
    validate_string($queue)
    $opt_queue = "  queue => \"${queue}\"\n"
  }

  if ($secret_access_key != '') {
    validate_string($secret_access_key)
    $opt_secret_access_key = "  secret_access_key => \"${secret_access_key}\"\n"
  }

  if ($sent_timestamp_field != '') {
    validate_string($sent_timestamp_field)
    $opt_sent_timestamp_field = "  sent_timestamp_field => \"${sent_timestamp_field}\"\n"
  }

  if ($md5_field != '') {
    validate_string($md5_field)
    $opt_md5_field = "  md5_field => \"${md5_field}\"\n"
  }

  if ($id_field != '') {
    validate_string($id_field)
    $opt_id_field = "  id_field => \"${id_field}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($aws_credentials_file != '') {
    validate_string($aws_credentials_file)
    $opt_aws_credentials_file = "  aws_credentials_file => \"${aws_credentials_file}\"\n"
  }

  if ($access_key_id != '') {
    validate_string($access_key_id)
    $opt_access_key_id = "  access_key_id => \"${access_key_id}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n sqs {\n${opt_access_key_id}${opt_add_field}${opt_aws_credentials_file}${opt_codec}${opt_debug}${opt_id_field}${opt_md5_field}${opt_queue}${opt_region}${opt_secret_access_key}${opt_sent_timestamp_field}${opt_tags}${opt_threads}${opt_type}${opt_use_ssl} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
