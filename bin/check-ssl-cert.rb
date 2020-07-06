#! /usr/bin/env ruby
#
#   check-ssl-cert
#
# DESCRIPTION:
#   Check when a SSL certificate will expire.
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
#   example commands
#
# NOTES:
#   Does it behave differently on specific platforms, specific use cases, etc
#
# LICENSE:
#   Jean-Francois Theroux <me@failshell.io>
#   Nathan Williams <nath.e.will@gmail.com>
#   Tom Braarup Cuykens <https://github.com/elfranne/>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'date'
require 'openssl'
require 'sensu-plugin/check/cli'

#
# Check SSL Cert
#
class CheckSSLCert < Sensu::Plugin::Check::CLI
  option :critical,
         description: 'Numbers of days left',
         short: '-c',
         long: '--critical DAYS',
         required: true

  option :warning,
         description: 'Numbers of days left',
         short: '-w',
         long: '--warning DAYS',
         required: true

  option :pem,
         description: 'Path to PEM file',
         short: '-P',
         long: '--pem PEM'

  option :host,
         description: 'Host to validate',
         short: '-h',
         long: '--host HOST'

  option :port,
         description: 'Port to validate',
         short: '-p',
         long: '--port PORT'

  option :servername,
         description: 'Set the TLS SNI (Server Name Indication) extension',
         short: '-s',
         long: '--servername SERVER'

  option :pkcs12,
         description: 'Path to PKCS#12 certificate',
         short: '-C',
         long: '--cert P12'

  option :pass,
         description: 'Pass phrase for the private key in PKCS#12 certificate',
         short: '-S',
         long: '--pass '

  option :starttls,
         description: 'Use StartTLS. OpenSSL 1.1.1 supports smtp, pop3, imap, ftp, xmpp, xmpp-server, irc, postgres, mysql, lmtp, nntp, sieve and ldap.',
         long: '--starttls PROTOCOL '

  def ssl_cert_expiry
    `openssl s_client -servername #{config[:servername]} -connect #{config[:host]}:#{config[:port]} \
    < /dev/null 2>&1 | openssl x509 -enddate -noout`.split('=').last
  end

  def ssl_cert_starttls
    `openssl s_client -servername #{config[:servername]} -connect #{config[:host]}:#{config[:port]} -starttls #{config[:starttls]} \
    < /dev/null 2>&1 | openssl x509 -enddate -noout`.split('=').last
  end

  def ssl_pem_expiry
    OpenSSL::X509::Certificate.new(File.read config[:pem]).not_after # rubocop:disable Style/NestedParenthesizedCalls
  end

  def ssl_pkcs12_expiry
    `openssl pkcs12 -in #{config[:pkcs12]} -nokeys -nomacver -passin pass:"#{config[:pass]}" | openssl x509 -noout -enddate | grep -v MAC`.split('=').last
  end

  def validate_opts
    if !config[:pem] && !config[:pkcs12]
      unknown 'Host and port required' unless config[:host] && config[:port]
    elsif config[:pem]
      unknown 'No such cert' unless File.exist? config[:pem]
    elsif config[:pkcs12]
      if !config[:pass]
        unknown 'No pass phrase specified for PKCS#12 certificate'
      else
        unknown 'No such cert' unless File.exist? config[:pkcs12]
      end
    end
    config[:servername] = config[:host] unless config[:servername]

    @starttls_supported_protocols = %w[smtp pop3 imap ftp xmpp xmpp-server irc postgres mysql lmtp nntp sieve ldap]
    unless @starttls_supported_protocols.include?(config[:starttls]) # rubocop: disable Style/GuardClause
      unknown "Unsupported StartTLS protocol #{config[:starttls]}" if config[:starttls]
    end
  end

  def run
    validate_opts
    expiry = if config[:pem]
               ssl_pem_expiry
             elsif config[:pkcs12]
               ssl_pkcs12_expiry
             elsif config[:starttls]
               ssl_cert_starttls
             else
               ssl_cert_expiry
             end

    days_until = (Date.parse(expiry.to_s) - Date.today).to_i

    if days_until < 0
      critical "Expired #{days_until.abs} days ago"
    elsif days_until < config[:critical].to_i
      critical "#{days_until} days left"
    elsif days_until < config[:warning].to_i
      warning "#{days_until} days left"
    else
      ok "#{days_until} days left"
    end
  end
end
