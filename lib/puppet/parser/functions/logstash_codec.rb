module Puppet::Parser::Functions
  newfunction(:logstash_codec, :type => :rvalue, :doc => <<-EOS
  Logstash codec function
    EOS
  ) do |arguments|

    # We only expect maximum of 2 arguments.
    raise(Puppet::ParseError, "logstash_codec_plain(): Wrong number of arguments given (#{arguments.size} given)") if arguments.size > 2

    codec_name = arguments[0]
    codec_config = arguments[1]

    # First argument is the codec name, this has to be a string
    unless codec_name.is_a?(String)
      raise(Puppet::ParseError, "logstash_codec(): Codec name requires to be a String")
    end

    # Second argument is the coded config, this has to be a hash.
    unless codec_config.nil? and codec_config.is_a?(Hash)
      raise(Puppet::ParseError, "logstash_codec(): Codec config requires to be a Hash")
    end

    case codec_name
      when 'dots'
        # No config

      when 'json'
        # No config

      when 'json_spooler'

        # spool_size - number
        unless codec_config['spool_size'].nil? and codec_config['spool_size'].is_a?(Number)
          opt_spool_size = "\t  spool_size => #{codec_config['spool_size']}\n"
        end

        opts_codec = "#{opt_spool_size}"


      when 'msgpack'

        # format - string
        unless codec_config['format'].nil? and codec_config['format'].is_a?(String)
          opt_format = "\t  format => #{codec_config['format']}\n"
        end

        opts_codec = "#{opt_format}"

      when 'multiline'

        # pattern - string
        unless codec_config['pattern'].nil? and codec_config['pattern'].is_a?(String)
          opt_pattern = "\t  pattern => #{codec_config['pattern']}\n"
        end

        # what - previous / next
        unless codec_config['what'].nil? and codec_config['what'].is_a?(String)
          if ['previous', 'next' ].include?(codec_config['what'])
            opt_what = "\t  what => #{codec_config['what']}\n"
          end
        end

        # negate - boolean
        unless codec_config['negate'].nil? and codec_config['negate'].is_a?(Bool)
          opt_negate = "\t  negate => #{codec_config['negate']}\n"
        end

       # patterns_dir - array
        unless codec_config['patterns_dir'].nil? and codec_config['patterns_dir'].is_a(Array)
          patterns_dir = codec_config['patterns_dir'].join("', '")
          opt_format = "\t  patterns_dir => ['"+patterns_dir+"']\n"
        end

        # charset - list
        unless codec_config['charset'].nil? and codec_config['charset'].is_a?(String)
          if [ 'UTF-8', 'bla', 'bla2', 'bla3' ].include?(codec_config['charset'])
            opt_charset = "\t  charset => #{codec_config['charset']}\n"
          end
        end

        opts_codec = "#{opt_pattern}#{opt_what}#{opt_negate}#{opt_format}#{opt_charset}"

      when 'noop'
        # No config

      when 'plain'

        unless codec_config['format'].nil?
          opt_format = "\t  format => #{codec_config['format']}\n"
        end

        unless codec_config['charset'].nil?
          if [ 'UTF-8', 'bla', 'bla2', 'bla3' ].include?(codec_config['charset'])
            opt_charset = "\t  charset => #{codec_config['charset']}\n"
          end
        end

        opts_codec = "#{opt_format}#{opt_charset}"

      when 'rubydebug'
        # No config

      when 'spool'
        # spool_size - number
        unless codec_config['spool_size'].nil? and codec_config['spool_size'].is_a?(Number)
          opt_spool_size = "\t  spool_size => #{codec_config['spool_size']}\n"
        end

        opts_codec = "#{opt_spool_size}"
       
      when 'line'
        # format - string
        unless codec_config['format'].nil?
          opt_format = "\t  format => #{codec_config['format']}\n"
        end

        # charset - string
        unless codec_config['charset'].nil?
          if [ 'UTF-8', 'bla', 'bla2', 'bla3' ].include?(codec_config['charset'])
            opt_charset = "\t  charset => #{codec_config['charset']}\n"
          end
        end

        opts_codec = "#{opt_format}#{opt_charset}"

      when 'oldlogstashjson '
        # no config

      else
        # We have an invalid codec name
        raise(Puppet::ParseError, "#{codec_name} is not a valid codec name")

    end # case codec_name

    opts = "\n#{opts_codec}\t" unless opts_codec.nil?
    result = "#{codec_name} {#{opts}}"
    return result

  end # do |arguments|

end
