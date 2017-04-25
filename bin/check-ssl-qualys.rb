#!/usr/bin/env ruby
# encoding: UTF-8
#  check-ssl-qualys.rb
#
# DESCRIPTION:
#   Runs a report using the Qualys SSL Labs API and then alerts if a
#   domain does not meet the grade specified for *ALL* hosts that are
#   reachable from that domian.
#
#   The checks that are performed are documented on
#   https://www.ssllabs.com/index.html as are the range of grades.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: rest-client
#
# USAGE:
#   # Basic usage
#   check-ssl-qualys.rb -d <domain_name>
#   # Specify the CRITICAL and WARNING grades to a specific grade
#   check-ssl-qualys.rb -d <domain_name> -c <critical_grade> -w <warning_grade>
#   # Use --api-url to specify an alternate api host
#   check-ssl-qualys.rb -d <domain_name> -api-url <alternate_host>
#
#  NOTE: This check takes a rather long time to run and will timeout if you're using
#  the default sensu check timeout.  Make sure to set a longer timeout period in the
#  check definition.  Two minutes or longer may be a good starting point as checks
#  regularly take 90+ seconds to run.
#
# LICENSE:
#   Copyright 2015 William Cooke <will@bruisyard.eu>
#   Released under the same terms as Sensu (the MIT license); see LICENSE for
#   details.
#

require 'sensu-plugin/check/cli'
require 'json'

# Checks a single DNS entry has a rating above a certain level
class CheckSSLQualys < Sensu::Plugin::Check::CLI
  # Current grades that are avaialble from the API
  GRADE_OPTIONS = ['A+', 'A', 'A-', 'B', 'C', 'D', 'E', 'F', 'T', 'M'].freeze

  option :domain,
         description: 'The domain to run the test against',
         short: '-d DOMAIN',
         long: '--domain DOMAIN',
         required: true

  option :api_url,
         description: 'The URL of the API to run against',
         long: '--api-url URL',
         default: 'https://api.ssllabs.com/api/v2/'

  option :warn,
         short: '-w GRADE',
         long: '--warn GRADE',
         description: 'WARNING if below this grade',
         proc: proc { |g| GRADE_OPTIONS.index(g) },
         default: 2 # 'A-'

  option :critical,
         short: '-c GRADE',
         long: '--critical GRADE',
         description: 'CRITICAL if below this grade',
         proc: proc { |g| GRADE_OPTIONS.index(g) },
         default: 3 # 'B'

  option :num_checks,
         short: '-n NUM_CHECKS',
         long: '--number-checks NUM_CHECKS',
         description: 'The number of checks to make before giving up (timeout of check)',
         proc: proc { |t| t.to_i },
         default: 24

  option :between_checks,
         short: '-t SECONDS',
         long: '--time-between SECONDS',
         description: 'The time between each poll of the API',
         proc: proc { |t| t.to_i },
         default: 10

  def ssl_api_request(from_cache)
    params = { host: config[:domain] }
    params[:startNew] = 'on' unless from_cache

    uri       = URI("#{config[:api_url]}analyze")
    uri.query = URI.encode_www_form(params)
    response  = Net::HTTP.get_response(uri)

    warning "Bad response recieved from API" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def ssl_check(from_cache)
    json = ssl_api_request(from_cache)
    warning "ERROR on #{config[:domain]} check" if json['status'] == 'ERROR'
    json
  end

  def ssl_recheck
    1.upto(config[:num_checks]) do |step|
      json = ssl_check(step != 1)
      return json if json['status'] == 'READY'
      sleep(config[:between_checks])
    end
    warning 'Timeout waiting for check to finish'
  end

  def ssl_grades
    ssl_recheck['endpoints'].map do |endpoint|
      endpoint['grade']
    end
  end

  def lowest_grade
    ssl_grades.sort_by! { |g| GRADE_OPTIONS.index(g) } .reverse![0]
  end

  def run
    grade = lowest_grade
    unless grade
      message "#{config[:domain]} not rated"
      critical
    end
    message "#{config[:domain]} rated #{grade}"
    grade_rank = GRADE_OPTIONS.index(grade)
    if grade_rank > config[:critical]
      critical
    elsif grade_rank > config[:warn]
      warning
    else
      ok
    end
  end
end
