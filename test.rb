require_relative './lib/cmd.rb'

cmd = CMD.new('C:/Ruby/2.0.0/x64/bin/ruby.exe C:/Development/wrk/github/execute/tests/timed_infinite_loop.rb')
cmd.execute_as('admin')