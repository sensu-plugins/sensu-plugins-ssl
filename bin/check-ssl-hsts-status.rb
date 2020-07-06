#!/usr/bin/env ruby

#  check-ssl-hsts-preload.rb
#
# DESCRIPTION:
#   Checks a domain against the chromium HSTS API reporting on the preload status of the domain
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
#   # Basic usage
#   check-ssl-hsts-preload.rb -d <domain_name>
#   # Specify the CRITICAL and WARNING alerts to either unknown (not in the database), pending or preloaded
#   check-ssl-hsts-preload.rb -d <domain_name> -c <critical_alert> -w <warning_alert>
#
# LICENSE:
#   Copyright 2017 Rowan Wookey <admin@rwky.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE for
#   details.
#
#   Inspired by https://github.com/sensu-plugins/sensu-plugins-ssl/blob/master/bin/check-ssl-qualys.rb Copyright 2015 William Cooke <will@bruisyard.eu>
#

require 'sensu-plugin/check/cli'
require 'json'
require 'net/http'

class CheckSSLHSTSStatus < Sensu::Plugin::Check::CLI
  STATUSES = %w[unknown pending preloaded].freeze

  option :domain,
         description: 'The domain to run the test against',
         short: '-d DOMAIN',
         long: '--domain DOMAIN',
         required: true

  option :warn,
         short: '-w STATUS',
         long: '--warn STATUS',
         description: 'WARNING if this status or worse',
         in: STATUSES,
         default: 'pending'

  option :critical,
         short: '-c STATUS',
         long: '--critical STATUS',
         description: 'CRITICAL if this status or worse',
         in: STATUSES,
         default: 'unknown'

  option :api_url,
         description: 'The URL of the API to run against',
         long: '--api-url URL',
         default: 'https://hstspreload.org/api/v2/status'

  def fetch(uri, limit = 10)
    if limit == 0
      return nil
    end

    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection then
      location = URI(response['location'])
      fetch(location, limit - 1)
    end
  end

  def run
    uri       = URI(config[:api_url])
    uri.query = URI.encode_www_form(domain: config[:domain])
    response  = fetch(uri)
    if response.nil?
      return warning 'Bad response recieved from API'
    end

    body = JSON.parse(response.body)
    unless STATUSES.include? body['status']
      warning 'Invalid status returned ' + body['status']
    end

    if STATUSES.index(body['status']) <= STATUSES.index(config[:critical])
      critical body['status']
    elsif STATUSES.index(body['status']) <= STATUSES.index(config[:warn])
      warning body['status']
    else
      ok
    end
  end
end

# vim: set tabstop=2 shiftwidth=2 expandtab:
