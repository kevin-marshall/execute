require 'dev'

task :test do
	Dir.chdir('tests') do |dir|
	  tests = Dir.glob('*_test.rb').each do |file|
	    cmd = Command.new("ruby #{file}")
		cmd.execute
	  end
	end
end

task :commit => [:add]

# Yard command line for realtime feed back of Readme.md modifications
# yard server --reload