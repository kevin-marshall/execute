require 'rspec'
require './lib/cmd.rb'

describe 'CMD' do
  CMD.default_options({ echo_command: false, echo_output: false })
  it 'should be able to execute: dir' do
    cmd = CMD.new('dir')
	cmd.execute
	expect(cmd[:output].empty?).to eq(false)
	expect(cmd[:output].include?('Directory')).to eq(true)
  end

  it 'should fail executing: isnotacommand' do
    cmd = CMD.new('isnotacommand')
	begin
		cmd.execute
		expect(true).to eq(false)
	rescue
	end
	expect(cmd[:exit_code]).to_not eq(0)
  end
  
  it 'should not have administrative privledges' do
    cmd = CMD.new('net session')
	begin
		cmd.execute
		expect(true).to eq(false)
	rescue
	end
	expect(cmd[:error].include?('Access is denied')).to eq(true)
	expect(cmd[:exit_code]).to_not eq(0)
  end
end
