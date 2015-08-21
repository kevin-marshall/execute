require 'rspec'
require './lib/cmd.rb'

describe 'CMD' do
  it 'should be able to execute: dir' do
    cmd = CMD.new('dir', { quiet: true })
	cmd.execute
	expect(cmd[:output].empty?).to eq(false)
	expect(cmd[:output].include?('Directory')).to eq(true)
  end

  it 'should fail executing: isnotacommand' do
    cmd = CMD.new('isnotacommand', { quiet: true })
	expect { cmd.execute }.to raise_error
	expect(cmd[:error].include?('No such file or directory')).to eq(true)
	expect(cmd[:exit_status]).to_not eq(0)
  end
end
