require_relative '../bin/check-ssl-anchor.rb'

describe CheckSSLRootIssuer do
  before(:all) do
    # Ensure the check isn't run when exiting (which is the default)
    CheckSSLRootIssuer.class_variable_set(:@@autorun, nil)
  end

  let(:check) do
    CheckSSLRootIssuer.new ['-u', 'https://philporada.com', '-i', '"CN=DST Root CA X3,O=Digital Signature Trust Co."']
  end

  it 'should pass check if the root issuer matches what the users -i flag' do
    expect(check).to receive(:ok).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end

  it 'should pass check if the root issuer matches what the users -i flag' do
    check.config[:anchor] = 'testdata'
    check.config[:regexp] = false
    expect(check).to receive(:critical).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end
end
