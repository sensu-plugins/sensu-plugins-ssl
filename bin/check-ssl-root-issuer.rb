#! /usr/bin/env ruby
#
#   check-ssl-root-issuer
#
# DESCRIPTION:
#   Check that a certificate is chained to a specific root certificate issuer
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
#   Check that a specific website is chained to a specific root certificate
#       ./check-ssl-root-issuer.rb \
#           -u https://example.com \
#           -i "CN=DST Root CA X3,O=Digital Signature Trust Co."
#
# LICENSE:
#   Copyright Jef Spaleta (jspaleta@gmail.com) 2020
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'openssl'
require 'uri'
require 'net/http'
require 'net/https'

#
# Check root certificate has specified issuer name
#
class CheckSSLRootIssuer < Sensu::Plugin::Check::CLI
  option :url,
         description: 'Url to check: Ex "https://google.com"',
         short: '-u',
         long: '--url URL',
         required: true

  option :issuer,
         description: 'An X509 certificate issuer name, RFC2253 format Ex: "CN=DST Root CA X3,O=Digital Signature Trust Co."',
         short: '-i',
         long: '--issuer ISSUER_NAME',
         required: true

  option :regexp,
         description: 'Treat the issuer name as a regexp',
         short: '-r',
         long: '--regexp',
         default: false,
         boolean: true,
         required: false

  option :format,
         description: 'optional issuer name format.',
         short: '-f',
         long: '--format FORMAT_VAL',
         default: 'RFC2253',
         in: %w[RFC2253 ONELINE COMPAT],
         required: false

  def cert_name_format
    # Note: because format argument is pre-validated by mixin 'in' logic eval is safe to use
    eval "OpenSSL::X509::Name::#{config[:format]}" # rubocop:disable Security/Eval, Style/EvalWithLocation
  end

  def validate_issuer(cert)
    issuer = cert.issuer.to_s(cert_name_format)
    if config[:regexp]
      issuer_regexp = Regexp.new(config[:issuer].to_s)
      issuer =~ issuer_regexp
    else
      issuer == config[:issuer].to_s
    end
  end

  def find_root_cert(uri)
    root_cert = nil
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 10
    http.use_ssl = true
    http.cert_store = OpenSSL::X509::Store.new
    http.cert_store.set_default_paths
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    http.verify_callback = lambda { |verify_ok, store_context|
      root_cert ||= store_context.current_cert
      unless verify_ok
        @failed_cert = store_context.current_cert
        @failed_cert_reason = [store_context.error, store_context.error_string] if store_context.error != 0
      end
      verify_ok
    }
    http.start {}
    root_cert
  end

  # Do the actual work and massage some data

  def run
    @fail_cert = nil
    @failed_cert_reason = 'Unknown'
    uri = URI.parse(config[:url])
    critical "url protocol must be https, you specified #{url}" if uri.scheme != 'https'
    root_cert = find_root_cert(uri)
    if @failed_cert
      msg = "Certificate verification failed.\n Reason: #{@failed_cert_reason}"
      critical msg
    end

    if validate_issuer(root_cert)
      msg = 'Root certificate in chain has expected issuer name'
      ok msg
    else
      msg = "Root certificate issuer did not match expected name.\nFound: \"#{root_cert.issuer.to_s(config[:issuer_format])}\""
      critical msg
    end
  end
end
