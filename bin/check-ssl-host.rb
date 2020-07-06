#!/usr/bin/env ruby

#  check-ssl-host.rb
#
# DESCRIPTION:
#   SSL certificate checker
#   Connects to a HTTPS (or other SSL) server and performs several checks on
#   the certificate:
#     - Is the hostname valid for the host we're requesting
#     - If any certificate chain is presented, is it valid (i.e. is each
#       certificate signed by the next)
#     - Is the certificate about to expire
#   Currently no checks are performed to make sure the certificate is signed
#   by a trusted authority.
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   # Basic usage
#   check-ssl-host.rb -h <hostname>
#   # Specify specific days before cert expiry to alert on
#   check-ssl-host.rb -h <hostmame> -c <critical_days> -w <warning_days>
#   # Use -p to specify an alternate port
#   check-ssl-host.rb -h <hostname> -p 8443
#   # Use --skip-hostname-verification and/or --skip-chain-verification to
#   # disable some of the checks made.
#   check-ssl-host.rb -h <hostname> --skip-chain-verification
#
# LICENSE:
#   Copyright 2014 Chef Software, Inc.
#   Released under the same terms as Sensu (the MIT license); see LICENSE for
#   details.
#

require 'sensu-plugin/check/cli'
require 'date'
require 'openssl'
require 'socket'

#
# Check SSL Host
#
class CheckSSLHost < Sensu::Plugin::Check::CLI
  STARTTLS_PROTOS = %w[smtp imap].freeze

  check_name 'check_ssl_host'

  option :critical,
         description: 'Return critical this many days before cert expiry',
         short: '-c',
         long: '--critical DAYS',
         proc: proc(&:to_i),
         default: 7

  option :warning,
         description: 'Return warning this many days before cert expiry',
         short: '-w',
         long: '--warning DAYS',
         required: true,
         proc: proc(&:to_i),
         default: 14

  option :host,
         description: 'Hostname of the server certificate to check, by default used as the server address if none ' \
                      'is given',
         short: '-h',
         long: '--host HOST',
         required: true

  option :port,
         description: 'Port on server to check',
         short: '-p',
         long: '--port PORT',
         default: 443

  option :address,
         description: 'Address of server to check. This is used instead of the host argument for the TCP connection, ' \
                      'however the server hostname is still used for the TLS/SSL context.',
         short: '-a',
         long: '--address ADDRESS'

  option :client_cert,
         description: 'Path to the client certificate in DER/PEM format',
         long: '--client-cert CERT'

  option :client_key,
         description: 'Path to the client RSA key in DER/PEM format',
         long: '--client-key KEY'

  option :skip_hostname_verification,
         description: 'Disables hostname verification',
         long: '--skip-hostname-verification',
         boolean: true

  option :skip_chain_verification,
         description: 'Disables certificate chain verification',
         long: '--skip-chain-verification',
         boolean: true

  option :starttls,
         description: 'use STARTTLS negotiation for the given protocol '\
                      "(#{STARTTLS_PROTOS.join(', ')})",
         long: '--starttls PROTO'

  def get_cert_chain(host, port, address, client_cert, client_key)
    tcp_client = TCPSocket.new(address || host, port)
    handle_starttls(config[:starttls], tcp_client) if config[:starttls]
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = OpenSSL::X509::Certificate.new File.read(client_cert) if client_cert
    ssl_context.key = OpenSSL::PKey::RSA.new File.read(client_key) if client_key
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)

    # If the OpenSSL version in use supports Server Name Indication (SNI, RFC 3546), then we set the hostname we
    # received to request that certificate.
    ssl_client.hostname = host if ssl_client.respond_to? :hostname=

    ssl_client.connect
    certs = ssl_client.peer_cert_chain
    ssl_client.close
    certs
  end

  def handle_starttls(proto, socket)
    if STARTTLS_PROTOS.include?(proto) # rubocop:disable Style/GuardClause
      send("starttls_#{proto}", socket)
    else
      raise ArgumentError, "STARTTLS supported only for #{STARTTLS_PROTOS.join(', ')}"
    end
  end

  def starttls_smtp(socket)
    status = socket.readline
    unless /^220 / =~ status
      critical "#{config[:host]} - did not receive initial SMTP 220"
      # no fall-through
    end
    socket.puts 'STARTTLS'

    status = socket.readline
    return if /^220 / =~ status

    critical "#{config[:host]} - did not receive SMTP 220 in response to STARTTLS"
  end

  def starttls_imap(socket)
    status = socket.readline
    unless /^* OK / =~ status
      critical "#{config[:host]} - did not receive initial * OK"
    end
    socket.puts 'a001 STARTTLS'

    status = socket.readline
    return if /^a001 OK Begin TLS negotiation now/ =~ status

    critical "#{config[:host]} - did not receive OK Begin TLS negotiation now"
  end

  def verify_expiry(cert)
    # Expiry check
    days = (cert.not_after.to_date - Date.today).to_i
    message = "#{config[:host]} - #{days} days until expiry"
    critical "#{config[:host]} - Expired #{days} days ago" if days < 0
    critical message if days < config[:critical]
    warning message if days < config[:warning]
    ok message
  end

  def verify_certificate_chain(certs)
    # Validates that a chain of certs are each signed by the next
    # NOTE: doesn't validate that the top of the chain is signed by a trusted
    # CA.
    valid = true
    parent = nil
    certs.reverse_each do |c|
      if parent
        valid &= c.verify(parent.public_key)
      end
      parent = c
    end
    critical "#{config[:host]} - Invalid certificate chain" unless valid
  end

  def verify_hostname(cert)
    unless OpenSSL::SSL.verify_certificate_identity(cert, config[:host]) # rubocop:disable Style/GuardClause
      critical "#{config[:host]} hostname mismatch (#{cert.subject})"
    end
  end

  def run
    chain = get_cert_chain(config[:host], config[:port], config[:address], config[:client_cert], config[:client_key])
    verify_hostname(chain[0]) unless config[:skip_hostname_verification]
    verify_certificate_chain(chain) unless config[:skip_chain_verification]
    verify_expiry(chain[0])
  rescue Errno::ECONNRESET => e
    critical "#{e.class} - #{e.message}"
  end
end
