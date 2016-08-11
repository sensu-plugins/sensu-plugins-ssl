#!/usr/bin/env ruby
#
#   check-java-keystore-cert
#
# DESCRIPTION:
#   Check when a certificate stored in a Java Keystore will expire
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

require 'date'
require 'sensu-plugin/check/cli'

class CheckJavaKeystoreCert < Sensu::Plugin::Check::CLI
  option :path,
         long: '--path PATH',
         description: '',
         required: true

  option :alias,
         long: '--alias ALIAS',
         description: '',
         required: true

  option :password,
         long: '--password PASSWORD',
         description: '',
         required: true

  option :warning,
         long: '--warning DAYS',
         description: '',
         proc: proc { |v| v.to_i },
         required: true

  option :critical,
         long: '--critical DAYS',
         description: '',
         proc: proc { |v| v.to_i },
         required: true

  def certificate_expiration_date
    result = `keytool -keystore #{config[:path]} \
                      -export -alias #{config[:alias]} \
                      -storepass #{config[:password]} 2>&1 | \
              openssl x509 -enddate -inform der -noout 2>&1`

    # rubocop:disable Style/SpecialGlobalVars
    unknown 'could not get certificate from keystore' unless $?.success?
    # rubocop:enable Style/SpecialGlobalVars

    Date.parse(result.split('=').last)
  end

  def validate_opts
    unknown 'warning cannot be less than critical' if config[:warning] < config[:critical]
  end

  def run
    validate_opts

    days_until = (certificate_expiration_date - Date.today).to_i

    if days_until < 0
      critical "Expired #{days_until.abs} days ago"
    elsif days_until < config[:critical]
      critical "#{days_until} days left"
    elsif days_until < config[:warning]
      warning "#{days_until} days left"
    end

    ok "#{days_until} days left"
  end
end
