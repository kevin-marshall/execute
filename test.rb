require_relative './lib/cmd.rb'

cmd = CMD.new('C:/Ruby/2.0.0/x64/bin/ruby.exe C:/Development/wrk/github/execute/test1.rb')
cmd.execute_as('admin')