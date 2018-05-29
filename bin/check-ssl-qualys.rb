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
require 'net/http'
require 'timeout'

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
         default: 'https://api.ssllabs.com/api/v3/'

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

  option :debug,
         long: '--debug BOOL',
         description: 'toggles extra debug printing',
         boolean: true,
         default: false

  option :num_checks,
         short: '-n NUM_CHECKS',
         long: '--number-checks NUM_CHECKS',
         description: 'The number of checks to make before giving up (timeout of check)',
         proc: proc { |t| t.to_i },
         default: 24

  option :between_checks,
         short: '-t SECONDS',
         long: '--time-between SECONDS',
         description: 'The fallback time between each poll of the API, when an ETA is given by the previous response and is higher than this value it is used',
         proc: proc { |t| t.to_i },
         default: 10

  option :timeout,
         long: '--timeout SECONDS',
         descriptions: 'the amount of seconds that this is allowed to run for',
         proc: proc(&:to_i),
         default: 300

  def ssl_api_request(from_cache)
    params = { host: config[:domain] }
    params[:startNew] = if from_cache == true
                          'off'
                        else
                          'on'
                        end

    uri       = URI("#{config[:api_url]}analyze")
    uri.query = URI.encode_www_form(params)
    begin
      response = Net::HTTP.get_response(uri)
    rescue StandardError => e
      warning e
    end

    warning 'Bad response recieved from API' unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def ssl_check(from_cache)
    json = ssl_api_request(from_cache)
    warning "ERROR on #{config[:domain]} check" if json['status'] == 'ERROR'
    json
  end

  def ssl_recheck
    1.upto(config[:num_checks]) do |step|
      p "step: #{step}" if config[:debug]
      start_time = Time.now
      p "start_time: #{start_time}" if config[:debug]
      json = if step == 1
               ssl_check(false)
             else
               ssl_check(true)
             end
      return json if json['status'] == 'READY'
      if json['endpoints'] && json['endpoints'].is_a?(Array)
        p "endpoints: #{json['endpoints']}" if config[:debug]
        # The api response sometimes has low eta (which seems unrealistic) from
        # my tests that can be 0 or low numbers which would imply it is done...
        # Basically we check if present and if its higher than the specified
        # time to wait between checks. If so we use the eta from the api get
        # response otherwise we use the time between check values. We have an
        # overall timeout that protects us from the api telling us to wait for
        # insanely long time periods. The highest I have seen the eta go was
        # around 250 seconds but put it in just in case as the api has very
        # erratic response times.
        if json['endpoints'].first.is_a?(Hash) && json['endpoints'].first.key?('eta') && json['endpoints'].first['eta'] > config[:between_checks]
          p "eta: #{json['endpoints'].first['eta']}" if config[:debug]
          sleep(json['endpoints'].first['eta'])
        else
          p "sleeping with default: #{config[:between_checks]}" if config[:debug]
          sleep(config[:between_checks])
        end
      end
      p "elapsed: #{Time.now - start_time}" if config[:debug]
      warning 'Timeout waiting for check to finish' if step == config[:num_checks]
    end
  end

  def ssl_grades
    ssl_recheck['endpoints'].map do |endpoint|
      endpoint['grade']
    end
  end

  def lowest_grade
    ssl_grades.sort_by! { |g| GRADE_OPTIONS.index(g) }.reverse![0]
  end

  def run
    Timeout.timeout(config[:timeout]) do
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
end
