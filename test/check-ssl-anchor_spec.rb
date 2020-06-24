require_relative '../bin/check-ssl-anchor.rb'

describe CheckSSLAnchor do
  before(:all) do
    # Ensure the check isn't run when exiting (which is the default)
    CheckSSLAnchor.class_variable_set(:@@autorun, nil)
  end

  let(:check) do
    CheckSSLAnchor.new ['-h', 'philporada.com', '-a', 'i:\/?O ?= ?Digital Signature Trust Co.,? ?\/?CN ?= ?DST Root CA X3', '-r']
  end

  it 'should pass check if the root anchor matches what the users -a flag' do
    expect(check).to receive(:ok).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end

  it 'should pass check if the root anchor matches what the users -a flag' do
    check.config[:anchor] = 'testdata'
    check.config[:regexp] = false
    expect(check).to receive(:critical).and_raise SystemExit
    expect { check.run }.to raise_error SystemExit
  end
end
