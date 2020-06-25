require_relative '../bin/check-ssl-hsts-preloadable.rb'
###
# If these randomly start failing then it's probably due to a change in the HSTS of the domain
# feel free to raise an issue and mention @rwky on github for a fix
###

describe CheckSSLHSTSPreloadable do
  before(:all) do
    # Ensure the check isn't run when exiting (which is the default)
    CheckSSLHSTSPreloadable.class_variable_set(:@@autorun, nil)
  end

  let(:check) do
    CheckSSLHSTSPreloadable.new ['-d', 'hstspreload.org']
  end

  it 'should pass check if the domain is preloadedable and has no warnings' do
    expect(check).to receive(:ok).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end

  ##
  # Disabled 2020/06/24 JDS
  # Reason:  the hsts-preloadable check depends on a domain lookup from https://hstspreload.org/
  #          There's no way to assure that an indexed domain at hstspreload.org will have a warning
  #          The previously tested domain 'oskuro.net' no longer issues a warning
  #          as its now incompliance with the hsts preload requirements.
  ##
  #  it 'should pass check if the domain is preloadedable but has warnings' do
  #    check.config[:domain] = 'oskuro.net'
  #    expect(check).to receive(:warning).and_raise SystemExit
  #    expect { check.run }.to raise_error SystemExit
  #  end

  it 'should pass check if not preloadedable' do
    check.config[:domain] = 'example.com'
    expect(check).to receive(:critical).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end
end
