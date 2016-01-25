require 'minitest/autorun'
require_relative('../lib/cmd_windows.rb')
require 'rbconfig'

ADMINISTRATIVE_USER='admin'

class CMD_windows_test < MiniTest::Unit::TestCase
  def setup
    CMD.default_options({ echo_command: false, echo_output: false, debug: false})
  end
  
 def test_execute_as
   cmd = CMD.new('net session')
   cmd.execute_as(ADMINISTRATIVE_USER)
   assert(!cmd[:error].include?('Access is denied'))
   assert(cmd[:exit_code] == 0)
   puts "CMD: #{cmd[:output]}"
 end
end
