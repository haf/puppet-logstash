# == Define: logstash::output::riemann
#
#   Riemann is a network event stream processing system.  While Riemann is
#   very similar conceptually to Logstash, it has much more in terms of
#   being a monitoring system replacement.  Riemann is used in Logstash
#   much like statsd or other metric-related outputs  You can learn about
#   Riemann here:  http://riemann.io/ You can see the author talk about it
#   here: http://vimeo.com/38377415
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
# [*debug*]
#   Enable debugging output?
#   Value type is boolean
#   Default value: false
#   This variable is optional
#
# [*host*]
#   The address of the Riemann server.
#   Value type is string
#   Default value: "localhost"
#   This variable is optional
#
# [*port*]
#   The port to connect to on your Riemann server.
#   Value type is number
#   Default value: 5555
#   This variable is optional
#
# [*protocol*]
#   The protocol to use UDP is non-blocking TCP is blocking  Logstash's
#   default output behaviour is to never lose events As such, we use tcp
#   as default here
#   Value can be any of: "tcp", "udp"
#   Default value: "tcp"
#   This variable is optional
#
# [*riemann_event*]
#   A Hash to set Riemann event fields (http://riemann.io/concepts.html).
#   The following event fields are supported: description, state, metric,
#   ttl, service  Tags found on the Logstash event will automatically be
#   added to the Riemann event.  Any other field set here will be passed
#   to Riemann as an event attribute.  Example:  riemann {
#   riemann_event =&gt; {         "metric"  =&gt; "%{metric}"
#   "service" =&gt; "%{service}"     } }   metric and ttl values will be
#   coerced to a floating point value. Values which cannot be coerced will
#   zero (0.0).  description, by default, will be set to the event message
#   but can be overridden here.
#   Value type is hash
#   Default value: None
#   This variable is optional
#
# [*sender*]
#   The name of the sender. This sets the host value in the Riemann event
#   Value type is string
#   Default value: "%{host}"
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
#  http://logstash.net/docs/1.2.2.dev/outputs/riemann
#
#  Need help? http://logstash.net/docs/1.2.2.dev/learn
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash::output::riemann (
  $codec         = '',
  $debug         = '',
  $host          = '',
  $port          = '',
  $protocol      = '',
  $riemann_event = '',
  $sender        = '',
  $instances     = [ 'agent' ]
) {

  require logstash::params

  File {
    owner => $logstash::logstash_user,
    group => $logstash::common::group
  }

  if $logstash::multi_instance == true {

    $confdirstart = prefix($instances, "${logstash::configdir}/")
    $conffiles    = suffix($confdirstart, "/config/output_riemann_${name}")
    $services     = prefix($instances, $logstash::params::service_base_name)
    $filesdir     = "${logstash::configdir}/files/output/riemann/${name}"

  } else {

    $conffiles = "${logstash::configdir}/conf.d/output_riemann_${name}"
    $services  = $logstash::params::service_name
    $filesdir  = "${logstash::configdir}/files/output/riemann/${name}"

  }

  #### Validate parameters

  validate_array($instances)

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

  if ($riemann_event != '') {
    validate_hash($riemann_event)
    $var_riemann_event = $riemann_event
    $arr_riemann_event = inline_template('<%= "["+@var_riemann_event.sort.collect { |k,v| "\"#{k}\", \"#{v}\"" }.join(", ")+"]" %>')
    $opt_riemann_event = "  riemann_event => ${arr_riemann_event}\n"
  }

  if ($port != '') {
    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    } else {
      $opt_port = "  port => ${port}\n"
    }
  }

  if ($protocol != '') {
    if ! ($protocol in ['tcp', 'udp']) {
      fail("\"${protocol}\" is not a valid protocol parameter value")
    } else {
      $opt_protocol = "  protocol => \"${protocol}\"\n"
    }
  }

  if ($sender != '') {
    validate_string($sender)
    $opt_sender = "  sender => \"${sender}\"\n"
  }

  if ($host != '') {
    validate_string($host)
    $opt_host = "  host => \"${host}\"\n"
  }

  #### Write config file

  file { $conffiles:
    ensure  => present,
    content => "output {\n riemann {\n${opt_codec}${opt_debug}${opt_host}${opt_port}${opt_protocol}${opt_riemann_event}${opt_sender} }\n}\n",
    mode    => '0440',
    notify  => Service[$services],
    require => Class['logstash::package', 'logstash::config']
  }
}
