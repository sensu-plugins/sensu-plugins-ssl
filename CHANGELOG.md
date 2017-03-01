#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

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

[unreleased]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/1.0.0...HEAD
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.6...1.0.0
[0.0.6]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.5...0.0.6
[0.0.5]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.4...0.0.5
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-ssl/compare/0.0.1...0.0.2
