## Sensu-Plugins-ssl

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-ssl.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-ssl)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-ssl.svg)](http://badge.fury.io/rb/sensu-plugins-ssl)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-ssl.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-ssl)

## Functionality

## Files
 * bin/check-ssl-cert.rb
 * bin/check-ssl-host.rb

## Usage

## Installation

Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install sensu-plugins-ssl -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

#### Rubygems

`gem install sensu-plugins-ssl`

#### Bundler

Add *sensu-plugins-ssl* to your Gemfile and run `bundle install` or `bundle update`

#### Chef

Using the Sensu **sensu_gem** LWRP
```
sensu_gem 'sensu-plugins-ssl' do
  options('--prerelease')
  version '0.0.1.alpha.1'
end
```

Using the Chef **gem_package** resource
```
gem_package 'sensu-plugins-ssl' do
  options('--prerelease')
  version '0.0.1.alpha.1'
end
```

## Notes
