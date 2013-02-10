# == Define: logstash::output::s3
#
#   TODO integrate awsconfig in the future INFORMATION: This plugin was
#   created for store the logstash's events into Amazon Simple Storage
#   Service (Amazon S3). For use it you needs authentications and an s3
#   bucket. Be careful to have the permission to write file on S3's bucket
#   and run logstash with super user for establish connection. S3 plugin
#   allows you to do something complex, let's explain:) S3 outputs create
#   temporary files into "/opt/logstash/S3temp/". If you want, you can
#   change the path at the start of register method. This files have a
#   special name, for example:
#   ls.s3.ip-10-228-27-95.2013-04-18T10.00.taghello.part0.txt ls.s3 :
#   indicate logstash plugin s3 "ip-10-228-27-95" : indicate you ip
#   machine, if you have more logstash and writing on the same bucket for
#   example. "2013-04-18T10.00" : represents the time whenever you specify
#   timefile. "taghello" : this indicate the event's tag, you can collect
#   events with the same tag. "part0" : this means if you indicate
#   sizefile then it will generate more parts if you file.size &gt;
#   size_file.        When a file is full it will pushed on bucket and
#   will be deleted in temporary directory.        If a file is empty is
#   not pushed, but deleted.   This plugin have a system to restore the
#   previous temporary files if something crash. INFORMATION ABOUT CLASS:
#   I tried to comment the class at best i could do. I think there are
#   much thing to improve, but if you want some points to develop here a
#   list: TODO Integrate aws_config in the future TODO Find a method to
#   push them all files when logtstash close the session. TODO Integrate
#   @field on the path file TODO Permanent connection or on demand? For
#   now on demand, but isn't a good implementation.   Use a while or a
#   thread to try the connection before break a time_out and signal an
#   error.   TODO If you have bugs report or helpful advice contact me,
#   but remember that this code is much mine as much as yours,   try to
#   work on it if you want :)   USAGE: This is an example of logstash
#   config: output {    s3{   access_key_id =&gt; "crazy_key"
#   (required)  secret_access_key =&gt; "monkey_access_key" (required)
#   endpoint_region =&gt; "eu-west-1"           (required)  bucket =&gt;
#   "boss_please_open_your_bucket" (required)           size_file =&gt;
#   2048                        (optional)  time_file =&gt; 5
#   (optional)  format =&gt; "plain"                        (optional)
#   canned_acl =&gt; "private"                  (optional. Options are
#   "private", "public_read", "public_read_write", "authenticated_read".
#   Defaults to "private" )      } } We analize this: accesskeyid =&gt;
#   "crazykey" Amazon will give you the key for use their service if you
#   buy it or try it. (not very much open source anyway) secretaccesskey
#   =&gt; "monkeyaccesskey" Amazon will give you the secretaccesskey for
#   use their service if you buy it or try it . (not very much open source
#   anyway). endpointregion =&gt; "eu-west-1" When you make a contract
#   with Amazon, you should know where the services you use. bucket =&gt;
#   "bosspleaseopenyourbucket" Be careful you have the permission to write
#   on bucket and know the name. sizefile =&gt; 2048 Means the size, in
#   KB, of files who can store on temporary directory before you will be
#   pushed on bucket. Is useful if you have a little server with poor
#   space on disk and you don't want blow up the server with unnecessary
#   temporary log files. timefile =&gt; 5 Means, in minutes, the time
#   before the files will be pushed on bucket. Is useful if you want to
#   push the files every specific time. format =&gt; "plain" Means the
#   format of events you want to store in the files canned_acl =&gt;
#   "private" The S3 canned ACL to use when putting the file. Defaults to
#   "private". LET'S ROCK AND ROLL ON THE CODE!
#
#
# === Parameters
#
# [*access_key_id*]
#   include LogStash::PluginMixins::AwsConfig Aws access_key.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*bucket*]
#   S3 bucket
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*canned_acl*]
#   Aws canned ACL
#   Value can be any of: "private", "public_read", "public_read_write",
#   "authenticated_read"
#   Default value: "private"
#   This variable is optional
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*endpoint_region*]
#   Aws endpoint_region
#   Value can be any of: "us-east-1", "us-west-1", "us-west-2",
#   "eu-west-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1",
#   "sa-east-1", "us-gov-west-1"
#   Default value: "us-east-1"
#   This variable is optional
#
# [*format*]
#   The event format you want to store in files. Defaults to plain text.
#   Value can be any of: "json", "plain", "nil"
#   Default value: "plain"
#   This variable is optional
#
# [*restore*]
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*secret_access_key*]
#   Aws secretaccesskey
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*size_file*]
#   Set the size of file in KB, this means that files on bucket when have
#   dimension &gt; file_size, they are stored in two or more file. If you
#   have tags then it will generate a specific size file for every tags
#   Value type is number
#   Default value: 0
#   This variable is optional
#
# [*time_file*]
#   Set the time, in minutes, to close the current subtimesection of
#   bucket. If you define filesize you have a number of files in
#   consideration of the section and the current tag. 0 stay all time on
#   listerner, beware if you specific 0 and sizefile 0, because you will
#   not put the file on bucket, for now the only thing this plugin can do
#   is to put the file when logstash restart.
#   Value type is number
#   Default value: 0
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
#  http://logstash.net/docs/1.2.2.dev/outputs/s3
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::s3 (
  $access_key_id     = '',
  $bucket            = '',
  $canned_acl        = '',
  $codec             = '',
  $endpoint_region   = '',
  $format            = '',
  $restore           = '',
  $secret_access_key = '',
  $size_file         = '',
  $time_file         = '',
  $instances         = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_s3_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/s3/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_s3_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/s3/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($restore != '') {
    validate_bool($restore)
    $opt_restore = "  restore => ${restore}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($size_file != '') {
    if ! is_numeric($size_file) {
      fail("\"${size_file}\" is not a valid size_file parameter value")
    } else {
      $opt_size_file = "  size_file => ${size_file}\n"
    }
  }

  if ($time_file != '') {
    if ! is_numeric($time_file) {
      fail("\"${time_file}\" is not a valid time_file parameter value")
    } else {
      $opt_time_file = "  time_file => ${time_file}\n"
    }
  }

  if ($endpoint_region != '') {
    if ! ($endpoint_region in ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'sa-east-1', 'us-gov-west-1']) {
      fail("\"${endpoint_region}\" is not a valid endpoint_region parameter value")
    } else {
      $opt_endpoint_region = "  endpoint_region => \"${endpoint_region}\"\n"
    }
  }

  if ($format != '') {
    if ! ($format in ['json', 'plain', 'nil']) {
      fail("\"${format}\" is not a valid format parameter value")
    } else {
      $opt_format = "  format => \"${format}\"\n"
    }
  }

  if ($canned_acl != '') {
    if ! ($canned_acl in ['private', 'public_read', 'public_read_write', 'authenticated_read']) {
      fail("\"${canned_acl}\" is not a valid canned_acl parameter value")
    } else {
      $opt_canned_acl = "  canned_acl => \"${canned_acl}\"\n"
    }
  }

  if ($secret_access_key != '') {
    validate_string($secret_access_key)
    $opt_secret_access_key = "  secret_access_key => \"${secret_access_key}\"\n"
  }

  if ($bucket != '') {
    validate_string($bucket)
    $opt_bucket = "  bucket => \"${bucket}\"\n"
  }

  if ($access_key_id != '') {
    validate_string($access_key_id)
    $opt_access_key_id = "  access_key_id => \"${access_key_id}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n s3 {\n${opt_access_key_id}${opt_bucket}${opt_canned_acl}${opt_codec}${opt_endpoint_region}${opt_format}${opt_restore}${opt_secret_access_key}${opt_size_file}${opt_time_file} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
