# frozen_string_literal: true

require_relative '../bin/check-ssl-crl.rb'

require 'timecop'

# rubocop:disable Metrics/BlockLength
describe CheckSSLCRL do
  before(:all) do
    # Ensure the check isn't run when exiting (which is the default)
    CheckSSLCRL.class_variable_set(:@@autorun, nil)
  end

  let(:check) do
    CheckSSLCRL.new ['--url', './test/fixtures/Class3SoftwarePublishers.crl', '--warning', '600', '--critical', '300']
  end

  it 'should pass check if the CRL has not expired' do
    expect(check).to receive(:ok).and_raise SystemExit
    Timecop.freeze(Time.new(2017, 1, 14)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return critical if the CRL has expired' do
    expect(check).to receive(:critical).with('./test/fixtures/Class3SoftwarePublishers.crl - Expired 1559 minutes ago').and_raise SystemExit
    Timecop.freeze(Time.new(2017, 2, 14)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return critical if the CRL will expire in less than 300 minutes' do
    expect(check).to receive(:critical).with('./test/fixtures/Class3SoftwarePublishers.crl - 120 minutes left, next update at 2017-02-12 21:00:09 UTC').and_raise SystemExit
    Timecop.freeze(Time.new(2017, 2, 12, 20, 0, 9)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return warning if the CRL will expire between 300 and 600 minutes from now' do
    expect(check).to receive(:warning).with('./test/fixtures/Class3SoftwarePublishers.crl - 420 minutes left, next update at 2017-02-12 21:00:09 UTC').and_raise SystemExit
    Timecop.freeze(Time.new(2017, 2, 12, 15, 0, 9)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return unknown if warning threshold is less than critical threshold' do
    check.config[:warning] = 1

    expect(check).to receive(:unknown).with('warning cannot be less than critical').and_raise SystemExit

    expect { check.run }.to raise_error SystemExit
  end
end
# rubocop:enable Metrics/BlockLength
