## Sensu-Plugins-SSL

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-ssl.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-ssl)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-ssl.svg)](http://badge.fury.io/rb/sensu-plugins-ssl)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-ssl)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-ssl.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-ssl)
[![Sensu Bonsai Asset](https://img.shields.io/badge/Bonsai-Download%20Me-brightgreen.svg?colorB=89C967&logo=sensu)](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-ssl)

## Sensu Asset
The Sensu assets packaged from this repository are built against the Sensu Ruby runtime environment. When using these assets as part of a Sensu Go resource (check, mutator or handler), make sure you include the corresponding Sensu Ruby runtime asset in the list of assets needed by the resource. The current ruby-runtime assets can be found [here](https://bonsai.sensu.io/assets/sensu/sensu-ruby-runtime) in the [Bonsai Asset Index](bonsai.sensu.io).
## Functionality

## Files
 * bin/check-java-keystore-cert.rb
 * bin/check-ssl-anchor.rb
 * bin/check-ssl-crl.rb
 * bin/check-ssl-cert.rb
 * bin/check-ssl-host.rb
 * bin/check-ssl-hsts-preload.rb
 * bin/check-ssl-hsts-preloadable.rb
 * bin/check-ssl-qualys.rb
 * bin/check-ssl-root-issuer.rb

## Usage

### `bin/check-ssl-anchor.rb`

Check that a specific website is chained to a specific root certificate (Let's Encrypt for instance). Requires the `openssl` commandline tool to be available on the system.

```
./bin/check-ssl-anchor.rb -u example.com -a "i:/O=Digital Signature Trust Co./CN=DST Root CA X3"
```

### `bin/check-ssl-crl.rb`

Checks a CRL has not or is not expiring by inspecting it's next update value.

You can check against a CRL file on disk:

```
./bin/check-ssl-crl -c 300 -w 600 -u /path/to/crl
```

or an online CRL:

```
./bin/check-ssl-crl -c 300 -w 600 -u http://www.website.com/file.crl
```

Critical and Warning thresholds are specified in minutes.

### `bin/check-ssl-qualys.rb`

Checks the ssllabs qualysis api for grade of your server, this check can be quite long so it should not be scheduled with a low interval and will probably need to adjust the check `timeout` options per the [check attributes spec](https://docs.sensu.io/sensu-core/1.2/reference/checks/#check-attributes) based on my tests you should expect this to take around 3 minutes.
```
./bin/check-ssl-qualys.rb -d google.com
```

### `bin/check-ssl-root-issuer.rb`

Check that a specific website is chained to a specific root certificate issuer. This is a pure Ruby implementation, does not require the openssl cmdline client tool to be installed.

```
./bin/check-ssl-root-issuer.rb -u example.com -a "CN=DST Root CA X3,O=Digital Signature Trust Co."
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Testing

To run the testing suite, you'll need to have a working `ruby` environment, `gem`, and `bundler` installed. We use `rake` to run the `rspec` tests automatically.

    bundle install
    bundle update
    bundle exec rake

## Notes

`bin/check-ssl-anchor.rb` and `bin/check-ssl-host.rb` would be good to run in combination with each other to test that the chain is anchored to a specific certificate and each certificate in the chain is correctly signed.
