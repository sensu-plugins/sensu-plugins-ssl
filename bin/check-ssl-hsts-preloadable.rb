#!/usr/bin/env ruby

# check-ssl-hsts-preloadable.rb
# DESCRIPTION:
#   Checks a domain against the chromium HSTS API returning errors/warnings if the domain is preloadable
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
#   check-ssl-hsts-preloadable.rb -d <domain_name>
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

class CheckSSLHSTSPreloadable < Sensu::Plugin::Check::CLI
  option :domain,
         description: 'The domain to run the test against',
         short: '-d DOMAIN',
         long: '--domain DOMAIN',
         required: true

  option :api_url,
         description: 'The URL of the API to run against',
         long: '--api-url URL',
         default: 'https://hstspreload.org/api/v2/preloadable'

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
    response = fetch(uri)
    if response.nil?
      return warning 'Bad response recieved from API'
    end

    body = JSON.parse(response.body)
    if !body['errors'].empty?
      critical body['errors'].map { |u| u['summary'] }.join(', ')
    elsif !body['warnings'].empty?
      warning body['warnings'].map { |u| u['summary'] }.join(', ')
    else
      ok
    end
  end
end

# vim: set tabstop=2 shiftwidth=2 expandtab:
