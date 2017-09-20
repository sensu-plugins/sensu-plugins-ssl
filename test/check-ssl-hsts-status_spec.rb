require_relative '../bin/check-ssl-hsts-status.rb'
###
# If these randomly start failing then it's probably due to a change in the HSTS of the domain
# feel free to raise an issue and mention @rwky on github for a fix
###

describe CheckSSLHSTSStatus do
  before(:all) do
    # Ensure the check isn't run when exiting (which is the default)
    CheckSSLHSTSStatus.class_variable_set(:@@autorun, nil)
  end

  let(:check) do
    CheckSSLHSTSStatus.new ['-d', 'hstspreload.org']
  end

  it 'should pass check if the domain is preloaded' do
    expect(check).to receive(:ok).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end

  it 'should pass check if not preloaded' do
    check.config[:domain] = 'example.com'
    expect(check).to receive(:critical).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end
end
