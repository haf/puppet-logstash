# == Define: logstash::output::sqs
#
#   Push events to an Amazon Web Services Simple Queue Service (SQS)
#   queue.  SQS is a simple, scalable queue system that is part of the
#   Amazon Web Services suite of tools.  Although SQS is similar to other
#   queuing systems like AMQP, it uses a custom API and requires that you
#   have an AWS account. See http://aws.amazon.com/sqs/ for more details
#   on how SQS works, what the pricing schedule looks like and how to
#   setup a queue.  To use this plugin, you must:  Have an AWS account
#   Setup an SQS queue Create an identify that has access to publish
#   messages to the queue. The "consumer" identity must have the following
#   permissions on the queue:  sqs:ChangeMessageVisibility
#   sqs:ChangeMessageVisibilityBatch sqs:GetQueueAttributes
#   sqs:GetQueueUrl sqs:ListQueues sqs:SendMessage sqs:SendMessageBatch
#   Typically, you should setup an IAM policy, create a user and apply the
#   IAM policy to the user. A sample policy is as follows:   {
#   "Statement": [      {        "Sid": "Stmt1347986764948",
#   "Action": [          "sqs:ChangeMessageVisibility",
#   "sqs:ChangeMessageVisibilityBatch",          "sqs:DeleteMessage",
#   "sqs:DeleteMessageBatch",          "sqs:GetQueueAttributes",
#   "sqs:GetQueueUrl",          "sqs:ListQueues",
#   "sqs:ReceiveMessage"        ],        "Effect": "Allow",
#   "Resource": [          "arn:aws:sqs:us-east-1:200850199751:Logstash"
#   ]      }    ]  }   See http://aws.amazon.com/iam/ for more details on
#   setting up AWS identities.
#
#
# === Parameters
#
# [*access_key_id*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*aws_credentials_file*]
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*batch*]
#   Set to true if you want send messages to SQS in batches with
#   batch_send from the amazon sdk
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*batch_events*]
#   If batch is set to true, the number of events we queue up for a
#   batch_send.
#   Value type is number
#   Default value: 10
#   This variable is optional
#
# [*batch_timeout*]
#   If batch is set to true, the maximum amount of time between batch_send
#   commands when there are pending events to flush.
#   Value type is number
#   Default value: 5
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*queue*]
#   Name of SQS queue to push messages into. Note that this is just the
#   name of the queue, not the URL or ARN.
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
#  http://logstash.net/docs/1.2.2.dev/outputs/sqs
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::sqs (
  $queue,
  $access_key_id        = '',
  $batch                = '',
  $batch_events         = '',
  $batch_timeout        = '',
  $codec                = '',
  $aws_credentials_file = '',
  $region               = '',
  $secret_access_key    = '',
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
    $conffiles    = suffix($confdirstart, "/config/output_sqs_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/sqs/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_sqs_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/sqs/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($batch != '') {
    validate_bool($batch)
    $opt_batch = "  batch => ${batch}\n"
  }

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

  if ($batch_events != '') {
    if ! is_numeric($batch_events) {
      fail("\"${batch_events}\" is not a valid batch_events parameter value")
    } else {
      $opt_batch_events = "  batch_events => ${batch_events}\n"
    }
  }

  if ($batch_timeout != '') {
    if ! is_numeric($batch_timeout) {
      fail("\"${batch_timeout}\" is not a valid batch_timeout parameter value")
    } else {
      $opt_batch_timeout = "  batch_timeout => ${batch_timeout}\n"
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
    content => "output {\n sqs {\n${opt_access_key_id}${opt_aws_credentials_file}${opt_batch}${opt_batch_events}${opt_batch_timeout}${opt_codec}${opt_queue}${opt_region}${opt_secret_access_key}${opt_use_ssl} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
