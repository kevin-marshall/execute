require 'minitest/autorun'
require_relative('../lib/cmd.rb')
require 'rbconfig'

#ADMINISTRATIVE_USER=''
ADMINISTRATIVE_USER='kevin'

class CMD_test < MiniTest::Unit::TestCase
  def setup
    CMD.default_options({ echo_command: false, echo_output: false, debug: false})
  end
  
  def test_command
    cmd = CMD.new('dir')
	cmd.execute
	assert(!cmd[:output].empty?)
	assert(true, cmd[:output].include?('Directory'))
  end

  def test_invalid_command
    cmd = CMD.new('isnotacommand')
	assert_raises(Exception) { cmd.execute }
  end

  def test_command_with_error
    cmd = CMD.new('net session')
	assert_raises(Exception) { cmd.execute }
	assert(cmd[:error].include?('Access is denied'))
	assert(cmd[:exit_code] != 0)
  end
  
  def test_command_with_error_ignore_exit_code
    cmd = CMD.new('net session', {ignore_exit_code: true})
	cmd.execute
	assert(cmd[:error].include?('Access is denied'))
	assert(cmd[:exit_code] != 0)
  end
 
  def test_execute_as
    cmd = CMD.new('net session')
	cmd.execute_as('kevin')
	assert(!cmd[:error].include?('Access is denied'))
	assert(cmd[:exit_code] == 0)
  end
end
