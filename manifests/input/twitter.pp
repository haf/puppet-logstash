# == Define: logstash::input::twitter
#
#   Read events from the twitter streaming api.
#
#
# === Parameters
#
# [*add_field*]
#   Add a field to an event
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*codec*]
#   The codec used for input data
#   Value type is codec
#   Default value: "plain"
#   This variable is optional
#
# [*consumer_key*]
#   Your twitter app's consumer key  Don't know what this is? You need to
#   create an "application" on twitter, see this url:
#   https://dev.twitter.com/apps/new
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*consumer_secret*]
#   Your twitter app's consumer secret  If you don't have one of these,
#   you can create one by registering a new application with twitter:
#   https://dev.twitter.com/apps/new
#   Value type is password
#   Default value: None
#   This variable is required
#
# [*debug*]
#   Set this to true to enable debugging on an input.
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*keywords*]
#   Any keywords to track in the twitter stream
#   Value type is array
#   Default value: None
#   This variable is required
#
# [*oauth_token*]
#   Your oauth token.  To get this, login to twitter with whatever account
#   you want, then visit https://dev.twitter.com/apps  Click on your app
#   (used with the consumerkey and consumersecret settings) Then at the
#   bottom of the page, click 'Create my access token' which will create
#   an oauth token and secret bound to your account and that application.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*oauth_token_secret*]
#   Your oauth token secret.  To get this, login to twitter with whatever
#   account you want, then visit https://dev.twitter.com/apps  Click on
#   your app (used with the consumerkey and consumersecret settings) Then
#   at the bottom of the page, click 'Create my access token' which will
#   create an oauth token and secret bound to your account and that
#   application.
#   Value type is password
#   Default value: None
#   This variable is required
#
# [*tags*]
#   Add any number of arbitrary tags to your event.  This can help with
#   processing later.
#   Value type is array
#   Default value: None
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
#  http://logstash.net/docs/1.2.2.dev/inputs/twitter
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::input::twitter (
  $keywords,
  $oauth_token_secret,
  $oauth_token,
  $consumer_key,
  $consumer_secret,
  $add_field          = '',
  $debug              = '',
  $codec              = '',
  $tags               = '',
  $type               = '',
  $instances          = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/input_twitter_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/input/twitter/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/input_twitter_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/input/twitter/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($tags != '') {
    validate_array($tags)
    $arr_tags = join($tags, '\', \'')
    $opt_tags = "  tags => ['${arr_tags}']\n"
  }

  if ($keywords != '') {
    validate_array($keywords)
    $arr_keywords = join($keywords, '\', \'')
    $opt_keywords = "  keywords => ['${arr_keywords}']\n"
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

  if ($consumer_secret != '') {
    validate_string($consumer_secret)
    $opt_consumer_secret = "  consumer_secret => \"${consumer_secret}\"\n"
  }

  if ($oauth_token_secret != '') {
    validate_string($oauth_token_secret)
    $opt_oauth_token_secret = "  oauth_token_secret => \"${oauth_token_secret}\"\n"
  }

  if ($oauth_token != '') {
    validate_string($oauth_token)
    $opt_oauth_token = "  oauth_token => \"${oauth_token}\"\n"
  }

  if ($type != '') {
    validate_string($type)
    $opt_type = "  type => \"${type}\"\n"
  }

  if ($consumer_key != '') {
    validate_string($consumer_key)
    $opt_consumer_key = "  consumer_key => \"${consumer_key}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "input {\n twitter {\n${opt_add_field}${opt_codec}${opt_consumer_key}${opt_consumer_secret}${opt_debug}${opt_keywords}${opt_oauth_token}${opt_oauth_token_secret}${opt_tags}${opt_type} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
