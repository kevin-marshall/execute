require 'minitest/autorun'
require_relative('../lib/cmd.rb')
require 'rbconfig'
require 'benchmark'
require 'timeout'
require 'sys/proctable'

class CMD_test < MiniTest::Unit::TestCase
  def setup
    CMD.default_options({ echo_command: false, echo_output: false, debug: false})
  end
  
  def test_command
    cmd = CMD.new('dir')
	cmd.execute
	assert(!cmd[:output].empty?)
	assert(cmd[:output].include?('Directory'))
  end

  def test_interrupt
	cmd = CMD.new('cmd /k C:\Windows\Notepad.exe', { timeout_signal: 'KILL' })
    Thread.new do
	  begin
		cmd.execute
      rescue => e
	  end
	end
	
	sleep(1)
	cmd.interrupt
	assert(Sys::ProcTable.ps(cmd[:pid]).nil?, "Failed to kill the spawned process: #{cmd[:pid]}")
 
    notepad_is_running = false
	Sys::ProcTable.ps { |p| notepad_is_running = true if(p.comm == 'notepad.exe') }
	assert(!notepad_is_running, "Notepad should have been killed when the command timed out")
  end
  
  def test_timeout
    timeout = 1
	cmd = CMD.new('cmd /k C:\Windows\Notepad.exe', { timeout: timeout, timeout_signal: 'KILL' })
	assert_raises(TimeoutError) { cmd.execute }
	assert(Sys::ProcTable.ps(cmd[:pid]).nil?, "Failed to kill the spawned process: #{cmd[:pid]}")
 
    notepad_is_running = false
	Sys::ProcTable.ps { |p| notepad_is_running = true if(p.comm == 'notepad.exe') }
	assert(!notepad_is_running, "Notepad should have been killed when the command timed out")
  end
  
  def test_invalid_command
    cmd = CMD.new('isnotacommand')
	assert_raises(StandardError) { cmd.execute }
  end

  def test_command_with_error
    cmd = CMD.new('net session')
	assert_raises(StandardError) { cmd.execute }
	assert(cmd[:error].include?('Access is denied'))
	assert(cmd[:exit_code] != 0)
  end
  
  def test_command_with_error_ignore_exit_code
    cmd = CMD.new('net session', {ignore_exit_code: true})
	cmd.execute
	assert(cmd[:error].include?('Access is denied'))
	assert(cmd[:exit_code] != 0)
  end
end
