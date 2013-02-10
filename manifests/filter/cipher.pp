# == Define: logstash::filter::cipher
#
#   This filter parses a source and apply a cipher or decipher before
#   storing it in the target.
#
#
# === Parameters
#
# [*add_field*]
#   If this filter is successful, add any arbitrary fields to this event.
#   Tags can be dynamic and include parts of the event using the %{field}
#   Example:  filter {   cipher {     add_field =&gt; [
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
#   syntax. Example:  filter {   cipher {     add_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would add a tag "foo_hello"
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*algorithm*]
#   The cipher algorythm  A list of supported algorithms can be obtained
#   by  puts OpenSSL::Cipher.ciphers
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*base64*]
#   Do we have to perform a base64 decode or encode?  If we are
#   decrypting, base64 decode will be done before. If we are encrypting,
#   base64 will be done after.
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# [*cipher_padding*]
#   Cypher padding to use. Enables or disables padding.  By default
#   encryption operations are padded using standard block padding and the
#   padding is checked and removed when decrypting. If the pad parameter
#   is zero then no padding is performed, the total amount of data
#   encrypted or decrypted must then be a multiple of the block size or an
#   error will occur.  See EVPCIPHERCTXsetpadding for further information.
#   We are using Openssl jRuby which uses default padding to PKCS5Padding
#   If you want to change it, set this parameter. If you want to disable
#   it, Set this parameter to 0  filter { cipher { padding =&gt; 0 }}
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*iv*]
#   The initialization vector to use  The cipher modes CBC, CFB, OFB and
#   CTR all need an "initialization vector", or short, IV. ECB mode is the
#   only mode that does not require an IV, but there is almost no
#   legitimate use case for this mode because of the fact that it does not
#   sufficiently hide plaintext patterns.
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*key*]
#   The key to use
#   Value type is string
#   Default value: None
#   This variable is optional
#
# [*key_pad*]
#   The character used to pad the key
#   Value type is String
#   Default value: "\x00"
#   This variable is optional
#
# [*key_size*]
#   The key size to pad  It depends of the cipher algorythm.I your key
#   don't need padding, don't set this parameter  Example, for AES-256, we
#   must have 32 char long key  filter { cipher { key_size =&gt; 32 }
#   Value type is number
#   Default value: 32
#   This variable is optional
#
# [*mode*]
#   Encrypting or decrypting some data  Valid values are encrypt or
#   decrypt
#   Value type is string
#   Default value: None
#   This variable is required
#
# [*remove_field*]
#   If this filter is successful, remove arbitrary fields from this event.
#   Fields names can be dynamic and include parts of the event using the
#   %{field} Example:  filter {   cipher {     remove_field =&gt; [
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
#   syntax. Example:  filter {   cipher {     remove_tag =&gt; [
#   "foo_%{somefield}" ]   } }   If the event has field "somefield" ==
#   "hello" this filter, on success, would remove the tag "foo_hello" if
#   it is present
#   Value type is array
#   Default value: []
#   This variable is optional
#
# [*source*]
#   The field to perform filter  Example, to use the @message field
#   (default) :  filter { cipher { source =&gt; "message" } }
#   Value type is string
#   Default value: "message"
#   This variable is optional
#
# [*target*]
#   The name of the container to put the result  Example, to place the
#   result into crypt :  filter { cipher { target =&gt; "crypt" } }
#   Value type is string
#   Default value: "message"
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
#  http://logstash.net/docs/1.2.2.dev/filters/cipher
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::filter::cipher (
  $algorithm,
  $mode,
  $key_size       = '',
  $base64         = '',
  $cipher_padding = '',
  $iv             = '',
  $key            = '',
  $key_pad        = '',
  $add_field      = '',
  $add_tag        = '',
  $remove_field   = '',
  $remove_tag     = '',
  $source         = '',
  $target         = '',
  $order          = 10,
  $instances      = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/filter_${order}_cipher_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/filter/cipher/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/filter_${order}_cipher_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/filter/cipher/${name}"

  }

  #### Validate parameters

  validate_array($instances)

  if ($add_tag != '') {
    validate_array($add_tag)
    $arr_add_tag = join($add_tag, '\', \'')
    $opt_add_tag = "  add_tag => ['${arr_add_tag}']\n"
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

  if ($base64 != '') {
    validate_bool($base64)
    $opt_base64 = "  base64 => ${base64}\n"
  }

  if ($add_field != '') {
    validate_hash($add_field)
    $var_add_field = $add_field
    $arr_add_field = inline_template('<%= "["+@var_add_field.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_add_field = "  add_field => ${arr_add_field}\n"
  }

  if ($key_size != '') {
    if ! is_numeric($key_size) {
      fail("\"${key_size}\" is not a valid key_size parameter value")
    } else {
      $opt_key_size = "  key_size => ${key_size}\n"
    }
  }

  if ($order != '') {
    if ! is_numeric($order) {
      fail("\"${order}\" is not a valid order parameter value")
    }
  }

  if ($key_pad != '') {
    $opt_key_pad = "  key_pad => \"${key_pad}\"\n"
  }

  if ($iv != '') {
    validate_string($iv)
    $opt_iv = "  iv => \"${iv}\"\n"
  }

  if ($cipher_padding != '') {
    validate_string($cipher_padding)
    $opt_cipher_padding = "  cipher_padding => \"${cipher_padding}\"\n"
  }

  if ($mode != '') {
    validate_string($mode)
    $opt_mode = "  mode => \"${mode}\"\n"
  }

  if ($algorithm != '') {
    validate_string($algorithm)
    $opt_algorithm = "  algorithm => \"${algorithm}\"\n"
  }

  if ($target != '') {
    validate_string($target)
    $opt_target = "  target => \"${target}\"\n"
  }

  if ($key != '') {
    validate_string($key)
    $opt_key = "  key => \"${key}\"\n"
  }

  if ($source != '') {
    validate_string($source)
    $opt_source = "  source => \"${source}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "filter {\n cipher {\n${opt_add_field}${opt_add_tag}${opt_algorithm}${opt_base64}${opt_cipher_padding}${opt_iv}${opt_key}${opt_key_pad}${opt_key_size}${opt_mode}${opt_remove_field}${opt_remove_tag}${opt_source}${opt_target} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
