#! /usr/bin/env ruby
#
#   check-ssl-anchor
#
# DESCRIPTION:
#   Check that a certificate is chained to a specific root certificate
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
#   Check that a specific website is chained to a specific root certificate (Let's Encrypt for instance)
#       ./check-ssl-anchor.rb \
#           -u example.com \
#           -a "i:/O=Digital Signature Trust Co./CN=DST Root CA X3"
#
# NOTES:
#   This is basically a ruby wrapper around the following openssl command.
#
#       openssl s_client -connect example.com:443 -servername example.com
#
#
#
#   Use the -s flag if you need to override SNI (Server Name Indication). If you
#   are seeing discrepencies between `openssl s_client` and browser, that's a good
#   indication to use this flag.
#
# LICENSE:
#   Copyright 2017 Phil Porada <philporada@gmail.com>
#
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'

#
# Check certificate is anchored to a specific root
#
class CheckSSLAnchor < Sensu::Plugin::Check::CLI
  option :host,
         description: 'Host to check',
         short: '-h',
         long: '--host HOST',
         required: true

  option :anchor,
         description: 'An anchor looks something like /O=Digital Signature Trust Co./CN=DST Root CA X3',
         short: '-a',
         long: '--anchor ANCHOR_VAL',
         required: true

  option :servername,
         description: 'Set the TLS SNI (Server Name Indication) extension',
         short: '-s',
         long: '--servername SERVER'

  option :port,
         description: 'Port on server to check',
         short: '-p',
         long: '--port PORT',
         default: 443

  def validate_opts
    config[:servername] = config[:host] unless config[:servername]
  end

  # Do the actual work and massage some data
  def anchor_information
    data = `openssl s_client \
                -connect #{config[:host]}:#{config[:port]} \
                -servername #{config[:servername]} < /dev/null 2>&1`.match(/Certificate chain(.*)---\nServer certificate/m)[1].split(/$/).map(&:strip)
    data = data.reject(&:empty?)

    unless data[0] =~ /0 s:\/CN=.*/m
      data = 'NOTOK'
    end
    data
  end

  def run
    validate_opts
    data = anchor_information
    if data == 'NOTOK'
      critical 'An error was encountered while trying to retrieve the certificate chain.'
    end

    if data[-1] == config[:anchor].to_s
      ok 'Root anchor has been found.'
    else
      critical 'Root anchor did not match. Found "' + data[-1] + '" instead.'
    end
  end
end
