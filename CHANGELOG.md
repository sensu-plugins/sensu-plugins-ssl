# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed [here](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md).

## [Unreleased]
- Remove ruby-2.3.0. Upgrade bundler. Fix failing tests (@phumpal).
- `check-ssl-cert.rb`: Support for StartTLS `--starttls PROTOCOL` (@elfranne)
- Upgrade to ruby 2.7 and Rubocop 0.86 and fix failing tests (@elfranne).

### Breaking Changes
- Bump `sensu-plugin` dependency from `~> 1.2` to `~> 4.0` you can read the changelog entries for [4.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#400---2018-02-17), [3.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#300---2018-12-04), and [2.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#v200---2017-03-29)

### Added
- Travis build automation to generate Sensu Asset tarballs that can be used n conjunction with Sensu provided ruby runtime assets and the Bonsai Asset Index
- Require latest sensu-plugin for [Sensu Go support](https://github.com/sensu-plugins/sensu-plugin#sensu-go-enablement)
- New option to treat anchor argument as a regexp
- New Check plugin `check-ssl-root-issuer.rb` with alternative logic for trust anchor verification.

### Changed
- `check-ssl-anchor.rb` uses regexp to test for present of certificates in cert chain that works with both openssl 1.0 and 1.1 formatting

### Fixed
- ssl-anchor test now uses regexp

## [2.0.1] - 2018-05-30
### Fixed
- `check-ssl-qualys.rb`: Fixed typo and removed timeout `-t` short option replacing it with `--timeout` as per previous changelog. `-t` conflicts with the short option for `--time-between`
- Fixed typo in changelog

## [2.0.0] - 2018-03-27
### Breaking Changes
- `check-ssl-qualys.rb`: when you submit a request with caching enabled it will return back a response including an eta key. Rather than sleeping for some arbitrary number of time we now use this key when its greater than `--time-between` to wait before attempting the next attempt to query. If it is lower or not present we fall back to `--time-between` (@majormoses)
- `check-ssl-qualys.rb`: new `--timeout` parameter to short circuit slow apis (@majormoses)

### Changed
- `check-ssl-qualys.rb`: updated `--api-url` to default to `v3` but remains backwards compatible (@jhoblitt) (@majormoses)

### Added
`check-ssl-qualys.rb`: option `--debug` to enable debug logging (@majormoses)

### Fixed
- `check-ssl-hsts-preloadable.rb`: Fixed testing warnings for if a domain can be HSTS preloaded (@rwky)

## [1.5.0] - 2017-09-26
### Added
- Ruby 2.4.1 testing
- `check-ssl-hsts-preload.rb`: Added check for testing preload status of HSTS (@rwky)
- `check-ssl-hsts-preloadable.rb`: Added check for testing if a domain can be HSTS preloaded (@rwky)

### Changed
- updated CHANGELOG guidelines location (@majormoses)

### Fixed
- `check-java-keystore-cert.rb`: Export cert in PEM format to fix tests that broke going from Precise to Trusty travis workers (@eheydrick)
- fixed spelling in github pr template (@majormoses)

## [1.4.0] - 2017-06-20
### Added
- `check-ssl-anchor.rb`: Add check for a specific root certificate signature. (@pgporada)
- `check-ssl-anchor_spec.rb`: Tests for the `check-ssl-anchor.rb` script (@pgporada)

## [1.3.1] - 2017-05-30
### Fixed
- `check-ssl-qualys.rb`: Fix missing `net/http` require that prevented the check from executing (@eheydrick)

## [1.3.0] 2017-05-18
### Changed
- `check-java-keystore-cert.rb`: Escape variables sent to shell on calls to keytool. (@rs-mrichmond)

## [1.2.0] - 2017-05-17
### Changed
- check-ssl-qualys.rb: removed dependency on rest-client so we don't need a c compiler (@baweaver)

## [1.1.0] - 2017-02-28
### Added
- `check-ssl-host.rb`: Add optional `address` command line parameter for specifying the address of the server to
   connect to, to override the `hostname` parameter (which is still used for verification/SNI) (@advance512)
- `check-ssl-host.rb`: Better error message when unable to connect to target host (@johntdyer)
- `check-ssl-host.rb`: Add support for client certificates (@modax)
- `check-ssl-host.rb`: Add basic IMAP STARTTLS negotiation (@lobeck)
- `check-java-keystore-cert.rb`: Add new check to verify a certificate in a Java Keystore has not expired. (@joerayme)
- `check-ssl-crl.rb`: Add check for expiring CRL (@shoekstra)

### Fixed
- `check-ssl-qualys.rb`: Handle API errors with status unknown instead of unhandled "Check failed to run". (@11mariom)
- `check-ssl-qualys.rb`: Handle nil grade_rank as critical not rated (@11mariom)

## [1.0.0]
### Changed
- Updated Rubocop to 0.40, applied auto-correct
- Loosened dependency on sensu-plugin from `= 1.2.0` to `~> 1.2`
- Changed permissions on check-ssl-qualys.rb to ensure it is executable

### Added
- check-ssl-cert.rb: Added optional `servername` configuration for specifying an SNI which may differ from the host

### Removed
- Removed Ruby 1.9.3 support; add Ruby 2.3.0 support to testing matrix

## [0.0.6] - 2015-08-18
### Fixed
- Added rest-client to the gemspec

## [0.0.5] - 2015-08-05
### Changed
- updated sensu-plugin gem to 1.2.0

### Added
- Basic support for STARTTLS negotiation (only SMTP to start with)

## [0.0.4] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

## [0.0.3] - 2015-06-18
### Added
- plugin to test SSL using the [Qualys SSL Test API](https://www.ssllabs.com/ssltest/)

## [0.0.2] - 2015-06-03
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## 0.0.1 - 2015-05-21
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/2.0.1...HEAD
[2.0.1]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.5.0...2.0.0
[1.5.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.4.0...1.5.0
[1.4.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.2.0...1.3.0
[1.2.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.6...1.0.0
[0.0.6]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.5...0.0.6
[0.0.5]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.4...0.0.5
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.1...0.0.2
