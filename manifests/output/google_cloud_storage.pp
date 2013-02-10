# == Define: logstash::output::google_cloud_storage
#
#   Copyright 2013 Google Inc.  Licensed under the Apache License, Version
#   2.0 (the "License"); you may not use this file except in compliance
#   with the License. You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0   Unless required by
#   applicable law or agreed to in writing, software distributed under the
#   License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for
#   the specific language governing permissions and limitations under the
#   License. Summary: plugin to upload log events to Google Cloud Storage
#   (GCS), rolling files based on the date pattern provided as a
#   configuration setting. Events are written to files locally and, once
#   file is closed, this plugin uploads it to the configured bucket.  For
#   more info on Google Cloud Storage, please go to:
#   https://cloud.google.com/products/cloud-storage  In order to use this
#   plugin, a Google service account must be used. For more information,
#   please refer to:
#   https://developers.google.com/storage/docs/authentication#service_accounts
#   Recommendation: experiment with the settings depending on how much log
#   data you generate, so the uploader can keep up with the generated
#   logs. Using gzip output can be a good option to reduce network traffic
#   when uploading the log files and in terms of storage costs as well.
#   USAGE: This is an example of logstash config:  output {
#   googlecloudstorage {   bucket =&gt; "my_bucket"
#   (required)  key_path =&gt; "/path/to/privatekey.p12"
#   (required)  key_password =&gt; "notasecret"
#   (optional)  service_account =&gt; "1234@developer.gserviceaccount.com"
#   (required)  temp_directory =&gt; "/tmp/logstash-gcs"
#   (optional)  log_file_prefix =&gt; "logstash_gcs"
#   (optional)  max_file_size_kbytes =&gt; 1024
#   (optional)  output_format =&gt; "plain"
#   (optional)  date_pattern =&gt; "%Y-%m-%dT%H:00"
#   (optional)  flush_interval_secs =&gt; 2
#   (optional)  gzip =&gt; false
#   (optional)  uploader_interval_secs =&gt; 60
#   (optional)      } }  Improvements TODO list: - Support logstash event
#   variables to determine filename. - Turn Google API code into a Plugin
#   Mixin (like AwsConfig). - There's no recover method, so if
#   logstash/plugin crashes, files may not be uploaded to GCS. - Allow
#   user to configure file name. - Allow parallel uploads for heavier
#   loads (+ connection configuration if exposed by Ruby API client)
#
#
# === Parameters
#
# [*bucket*]
#   GCS bucket name, without "gs://" or any other prefix.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*codec*]
#   The codec used for output data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*date_pattern*]
#   Time pattern for log file, defaults to hourly files. Must
#   Time.strftime patterns:
#   www.ruby-doc.org/core-2.0/Time.html#method-i-strftime
#   Value type is string
#   Default value: "%Y-%m-%dT%H:00"
#   This variable is optional
#
# [*flush_interval_secs*]
#   Flush interval in seconds for flushing writes to log files. 0 will
#   flush on every message.
#   Value type is number
#   Default value: 2
#   This variable is optional
#
# [*gzip*]
#   Gzip output stream when writing events to log files.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*key_password*]
#   GCS private key password.
#   Value type is string
#   Default value: "notasecret"
#   This variable is optional
#
# [*key_path*]
#   GCS path to private key file.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*log_file_prefix*]
#   Log file prefix. Log file will follow the format:
#   hostnamedate&lt;.part?&gt;.log
#   Value type is string
#   Default value: "logstash_gcs"
#   This variable is optional
#
# [*max_file_size_kbytes*]
#   Sets max file size in kbytes. 0 disable max file check.
#   Value type is number
#   Default value: 10000
#   This variable is optional
#
# [*output_format*]
#   The event format you want to store in files. Defaults to plain text.
#   Value can be any of: "json", "plain"
#   Default value: "plain"
#   This variable is optional
#
# [*service_account*]
#   GCS service account.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*temp_directory*]
#   Directory where temporary files are stored. Defaults to
#   /tmp/logstash-gcs-
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*uploader_interval_secs*]
#   Uploader interval when uploading new files to GCS. Adjust time based
#   on your time pattern (for example, for hourly files, this interval can
#   be around one hour).
#   Value type is number
#   Default value: 60
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
#  http://logstash.net/docs/1.2.2.dev/outputs/google_cloud_storage
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::google_cloud_storage (
  $bucket,
  $service_account,
  $key_path,
  $log_file_prefix        = '',
  $flush_interval_secs    = '',
  $gzip                   = '',
  $key_password           = '',
  $date_pattern           = '',
  $max_file_size_kbytes   = '',
  $output_format          = '',
  $codec                  = '',
  $temp_directory         = '',
  $uploader_interval_secs = '',
  $instances              = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_google_cloud_storage_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/google_cloud_storage/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_google_cloud_storage_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/google_cloud_storage/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($gzip != '') {
    validate_bool($gzip)
    $opt_gzip = "  gzip => ${gzip}\n"
  }

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($flush_interval_secs != '') {
    if ! is_numeric($flush_interval_secs) {
      fail("\"${flush_interval_secs}\" is not a valid flush_interval_secs parameter value")
    } else {
      $opt_flush_interval_secs = "  flush_interval_secs => ${flush_interval_secs}\n"
    }
  }

  if ($uploader_interval_secs != '') {
    if ! is_numeric($uploader_interval_secs) {
      fail("\"${uploader_interval_secs}\" is not a valid uploader_interval_secs parameter value")
    } else {
      $opt_uploader_interval_secs = "  uploader_interval_secs => ${uploader_interval_secs}\n"
    }
  }

  if ($max_file_size_kbytes != '') {
    if ! is_numeric($max_file_size_kbytes) {
      fail("\"${max_file_size_kbytes}\" is not a valid max_file_size_kbytes parameter value")
    } else {
      $opt_max_file_size_kbytes = "  max_file_size_kbytes => ${max_file_size_kbytes}\n"
    }
  }

  if ($output_format != '') {
    if ! ($output_format in ['json', 'plain']) {
      fail("\"${output_format}\" is not a valid output_format parameter value")
    } else {
      $opt_output_format = "  output_format => \"${output_format}\"\n"
    }
  }

  if ($log_file_prefix != '') {
    validate_string($log_file_prefix)
    $opt_log_file_prefix = "  log_file_prefix => \"${log_file_prefix}\"\n"
  }

  if ($key_path != '') {
    validate_string($key_path)
    $opt_key_path = "  key_path => \"${key_path}\"\n"
  }

  if ($service_account != '') {
    validate_string($service_account)
    $opt_service_account = "  service_account => \"${service_account}\"\n"
  }

  if ($key_password != '') {
    validate_string($key_password)
    $opt_key_password = "  key_password => \"${key_password}\"\n"
  }

  if ($temp_directory != '') {
    validate_string($temp_directory)
    $opt_temp_directory = "  temp_directory => \"${temp_directory}\"\n"
  }

  if ($date_pattern != '') {
    validate_string($date_pattern)
    $opt_date_pattern = "  date_pattern => \"${date_pattern}\"\n"
  }

  if ($bucket != '') {
    validate_string($bucket)
    $opt_bucket = "  bucket => \"${bucket}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n google_cloud_storage {\n${opt_bucket}${opt_codec}${opt_date_pattern}${opt_flush_interval_secs}${opt_gzip}${opt_key_password}${opt_key_path}${opt_log_file_prefix}${opt_max_file_size_kbytes}${opt_output_format}${opt_service_account}${opt_temp_directory}${opt_uploader_interval_secs} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
