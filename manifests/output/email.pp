# == Define: logstash::output::email
#
#   Send email when any event is received.
#
#
# === Parameters
#
# [*attachments*]
#   attachments - has of name of file and file location
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*body*]
#   body for email - just plain text
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*cc*]
#   Who to CC on this email?  See "to" setting for what is valid here.
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
# [*contenttype*]
#   contenttype : for multipart messages, set the content type and/or
#   charset of the html part
#   Value type is string
#   Default value: "text/html; charset=UTF-8"
#   This variable is optional
#
# [*from*]
#   The From setting for email - fully qualified email address for the
#   From:
#   Value type is string
#   Default value: "logstash.alert@nowhere.com"
#   This variable is optional
#
# [*htmlbody*]
#   body for email - can contain html markup
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*options*]
#   the options to use: smtp: address, port, enablestarttlsauto,
#   user_name, password, authentication(bool), domain sendmail: location,
#   arguments If you do not specify anything, you will get the following
#   equivalent code set in every new mail object:    Mail.defaults do
#   delivery_method :smtp, { :address              =&gt; "localhost",
#   :port                 =&gt; 25,                          :domain
#   =&gt; 'localhost.localdomain',                          :user_name
#   =&gt; nil,                          :password             =&gt; nil,
#   :authentication       =&gt; nil,(plain, login and cram_md5)
#   :enable_starttls_auto =&gt; true  }  retriever_method :pop3, {
#   :address             =&gt; "localhost",
#   :port                =&gt; 995,                           :user_name
#   =&gt; nil,                           :password            =&gt; nil,
#   :enable_ssl          =&gt; true }     end    Mail.deliverymethod.new
#   #=&gt; Mail::SMTP instance   Mail.retrievermethod.new #=&gt;
#   Mail::POP3 instance  Each mail object inherits the default set in
#   Mail.delivery_method, however, on a per email basis, you can override
#   the method:    mail.delivery_method :sendmail  Or you can override the
#   method and pass in settings:    mail.delivery_method :sendmail, {
#   :address =&gt; 'some.host' }  You can also just modify the settings:
#   mail.delivery_settings = { :address =&gt; 'some.host' }  The passed in
#   hash is just merged against the defaults with +merge!+ and the result
#   assigned the mail object.  So the above example will change only the
#   :address value of the global smtp_settings to be 'some.host', keeping
#   all other values
#   Value type is hash
#   Default value: {}
#   This variable is optional
#
# [*replyto*]
#   The Reply-To setting for email - fully qualified email address is
#   required here.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*subject*]
#   subject for email
#   Value type is string
#   Default value: ""
#   This variable is optional
#
# [*to*]
#   Who to send this email to? A fully qualified email address to send to
#   This field also accept a comma separated list of emails like
#   "me@host.com, you@host.com"  You can also use dynamic field from the
#   event with the %{fieldname} syntax.
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*via*]
#   how to send email: either smtp or sendmail - default to 'smtp'
#   Value type is string
#   Default value: "smtp"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/email
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::email (
  $to,
  $cc           = '',
  $codec        = '',
  $contenttype  = '',
  $from         = '',
  $htmlbody     = '',
  $body         = '',
  $options      = '',
  $replyto      = '',
  $subject      = '',
  $attachments  = '',
  $via          = '',
  $instances    = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_email_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/email/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_email_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/email/${name}"

  }

  #### Validate parameters
  if ($attachments != '') {
    validate_array($attachments)
    $arr_attachments = join($attachments, '\', \'')
    $opt_attachments = "  attachments => ['${arr_attachments}']\n"
  }


  validate_array($instances)

  if ($codec != '') {
    if ! ($codec in codec) {
      fail("\"${codec}\" is not a valid codec parameter value")
    } else {
      $opt_codec = "  codec => \"${codec}\"\n"
    }
  }

  if ($options != '') {
    validate_hash($options)
    $var_options = $options
    $arr_options = inline_template('<%= "["+@var_options.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_options = "  options => ${arr_options}\n"
  }

  if ($replyto != '') {
    validate_string($replyto)
    $opt_replyto = "  replyto => \"${replyto}\"\n"
  }

  if ($cc != '') {
    validate_string($cc)
    $opt_cc = "  cc => \"${cc}\"\n"
  }

  if ($from != '') {
    validate_string($from)
    $opt_from = "  from => \"${from}\"\n"
  }

  if ($htmlbody != '') {
    validate_string($htmlbody)
    $opt_htmlbody = "  htmlbody => \"${htmlbody}\"\n"
  }

  if ($subject != '') {
    validate_string($subject)
    $opt_subject = "  subject => \"${subject}\"\n"
  }

  if ($body != '') {
    validate_string($body)
    $opt_body = "  body => \"${body}\"\n"
  }

  if ($to != '') {
    validate_string($to)
    $opt_to = "  to => \"${to}\"\n"
  }

  if ($via != '') {
    validate_string($via)
    $opt_via = "  via => \"${via}\"\n"
  }

  if ($contenttype != '') {
    validate_string($contenttype)
    $opt_contenttype = "  contenttype => \"${contenttype}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n email {\n${opt_attachments}${opt_body}${opt_cc}${opt_codec}${opt_contenttype}${opt_from}${opt_htmlbody}${opt_options}${opt_replyto}${opt_subject}${opt_to}${opt_via} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
