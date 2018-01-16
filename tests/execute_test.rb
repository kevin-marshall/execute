require 'minitest/autorun'
require_relative('../lib/execute.rb')
require 'rbconfig'
require 'benchmark'
require 'timeout'
require 'sys/proctable'

class Execute_test < MiniTest::Test
  def setup
    Execute.default_options({ echo_command: false, echo_output: false, debug: false})
  end
  
  def test_command
    cmd = Execute.new('dir')
	  cmd.execute
	  assert(!cmd[:output].empty?)
	  assert(cmd[:output].include?('Directory'))
  end

  def test_interrupt
	  cmd = Execute.new('cmd /k C:\Windows\Notepad.exe', { timeout_signal: 'KILL' })
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
  
  def running?(process_name)
    running = false
	  Sys::ProcTable.ps { |p| notepad_is_running = true if(p.comm == 'notepad.exe') }
	  return running
  end
  
  def test_timeout
	  assert(!running?('notepad.exe'), "An instance of Notepad is running, cannot perform test.")

    timeout = 1
	  cmd = Execute.new('cmd /k C:\Windows\Notepad.exe', { timeout: timeout, timeout_signal: 'KILL' })
	  assert_raises(Exception) { cmd.execute }
	  assert(Sys::ProcTable.ps(cmd[:pid]).nil?, "Failed to kill the spawned process: #{cmd[:pid]}")
 
 	  assert(!running?('notepad.exe'), "Notepad should have been killed when the command timed out")
  end
  
  def test_pre_timeout_command
    `ocra CreateFile.rb` unless(File.exists?('CreateFile.exe'))
	
    file = './pre_timeout.txt'
		File.delete(file) if(File.exists?(file))
	
		pre_timeout_command = "CreateFile.exe #{file}"
	
    timeout = 1
		options = { timeout: timeout, timeout_signal: 'KILL', pre_timeout_command: Execute.new(pre_timeout_command) }
		cmd = Execute.new('cmd /k C:\Windows\Notepad.exe', options)
		assert_raises(Exception) { cmd.execute }
		assert(File.exists?(file), "#{file} should have been created")
  end
  
  def test_invalid_command
    cmd = Execute.new('isnotacommand')
	  assert_raises(StandardError) { cmd.execute }
  end

  def test_command_with_error
    cmd = Execute.new('net session')
	  assert_raises(StandardError) { cmd.execute }
	  assert(cmd[:error].include?('Access is denied'))
	  assert(cmd[:exit_code] != 0)
  end
  
  def test_command_with_error_ignore_exit_code
    cmd = Execute.new('net session', {ignore_exit_code: true})
	  cmd.execute
	  assert(cmd[:error].include?('Access is denied'))
 	  assert(cmd[:exit_code] != 0)
  end
end
