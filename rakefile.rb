require 'dev'
require 'rbconfig'

task :test do
	Dir.chdir('tests') do |dir|
	  cmd = Command.new("#{RbConfig::CONFIG['bindir']}/ruby.exe all_tests.rb")
	  cmd.execute
	  
	  puts "Output: #{cmd[:output]}"
	end
end

task :commit => [:add]

# Yard command line for realtime feed back of Readme.md modifications
# yard server --reload