#! /usr/bin/env ruby
#
#   check-ssl-crl
#
# DESCRIPTION:
#   Check in minutes when a certificate revocation list will expire.
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
#   ./check-ssl-crl -c 300 -w 600 -u /path/to/crl
#   ./check-ssl-crl -c 300 -w 600 -u http://www.website.com/file.crl
#
# LICENSE:
#   Stephen Hoekstra <shoekstra@schubergphilis.com>
#
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'open-uri'
require 'openssl'
require 'sensu-plugin/check/cli'
require 'time'

#
# Check SSL Cert
#
class CheckSSLCRL < Sensu::Plugin::Check::CLI
  option :critical,
         description: 'Numbers of minutes left',
         short: '-c',
         long: '--critical MINUTES',
         proc: proc { |v| v.to_i },
         required: true

  option :url,
         description: 'URL (or path) to CRL file',
         short: '-u',
         long: '--url URL',
         required: true

  option :warning,
         description: 'Numbers of minutes left',
         short: '-w',
         long: '--warning MINUTES',
         proc: proc { |v| v.to_i },
         required: true

  def seconds_to_minutes(seconds)
    (seconds / 60).to_i
  end

  def validate_opts
    unknown 'warning cannot be less than critical' if config[:warning] < config[:critical]
  end

  def run
    validate_opts

    next_update = OpenSSL::X509::CRL.new(open(config[:url]).read).next_update # rubocop:disable Security/Open
    minutes_until = seconds_to_minutes(Time.parse(next_update.to_s) - Time.now)

    critical "#{config[:url]} - Expired #{minutes_until.abs} minutes ago" if minutes_until < 0
    critical "#{config[:url]} - #{minutes_until} minutes left, next update at #{next_update}" if minutes_until < config[:critical].to_i
    warning "#{config[:url]} - #{minutes_until} minutes left, next update at #{next_update}" if minutes_until < config[:warning].to_i
    ok "#{config[:url]} - #{minutes_until} minutes left, next update at #{next_update}"
  end
end
