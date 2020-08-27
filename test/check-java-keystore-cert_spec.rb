# frozen_string_literal: true

require_relative '../bin/check-java-keystore-cert.rb'

require 'timecop'

# rubocop:disable Metrics/BlockLength
describe CheckJavaKeystoreCert do
  before(:all) do
    # Ensure the check isn't run when exiting (which is the default)
    CheckJavaKeystoreCert.class_variable_set(:@@autorun, nil)
  end

  let(:check) do
    CheckJavaKeystoreCert.new ['--path', './test/fixtures/test_store.jks', '--password', 'password', '--alias', 'certificate', '--warning', '15', '--critical', '5']
  end

  it 'should pass check if the certificate has not expired' do
    expect(check).to receive(:ok).with('30 days left').and_raise SystemExit
    Timecop.freeze(Date.new(2016, 8, 11)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return critical if the certificate has expired' do
    expect(check).to receive(:critical).with('Expired 81 days ago').and_raise SystemExit
    Timecop.freeze(Date.new(2016, 11, 30)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return critical if the certificate will expire in less than 5 days' do
    expect(check).to receive(:critical).with('1 days left').and_raise SystemExit
    Timecop.freeze(Date.new(2016, 9, 9)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return warning if the certificate will expire between 5 and 15 days from now' do
    expect(check).to receive(:warning).with('9 days left').and_raise SystemExit
    Timecop.freeze(Date.new(2016, 9, 1)) do
      expect { check.run }.to raise_error SystemExit
    end
  end

  it 'should return unknown if warning days are less than critical' do
    check.config[:warning] = 1

    expect(check).to receive(:unknown).with('warning cannot be less than critical').and_raise SystemExit

    expect { check.run }.to raise_error SystemExit
  end

  it 'should return unknown if keystore cannot be read' do
    check.config[:path] = 'nonexistent'

    expect(check).to receive(:unknown).with('could not get certificate from keystore').and_raise SystemExit

    expect { check.run }.to raise_error SystemExit
  end

  it 'should return unknown if keystore password wrong' do
    check.config[:password] = 'incorrect'

    expect(check).to receive(:unknown).with('could not get certificate from keystore').and_raise SystemExit

    expect { check.run }.to raise_error SystemExit
  end
end
# rubocop:enable Metrics/BlockLength
