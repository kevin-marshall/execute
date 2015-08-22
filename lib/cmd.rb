require 'open3'

class CMD < Hash
  def initialize(cmd, options=nil)
   self[:output] = ''
   self[:error] = ''
   self[:ignore_exit_code] = false
   self[:debug] = false
   self[:quiet] = false

   options.each { |key, value| self[key] = value} unless(options.nil?)
   self[:command]=cmd
  end
  
  def execute
    begin
	  puts self[:command] unless(self[:quiet])
	  cmd = self[:command]
	  cmd = "runas /savecred /user:#{self[:admin_user]} \"#{cmd}\"" if(has_key?(:admin_user))
      self[:output],self[:error], self[:exit_code] = Open3.capture3(cmd, :stdin_data => STDIN)
      self[:exit_code]=self[:exit_code].to_i
	rescue Exception => e
	  self[:error] = "Exception: " + e.to_s
	  self[:exit_code]=1 unless(has_key?(:exit_code))
	end

	if(self[:debug])
	  puts "command: #{self[:command]}" if(self[:quiet])
	  puts "output: #{self[:output]}"
	  puts "error: #{self[:error]}"
	  puts "exit_code: #{self[:exit_code]}"
	end
	
	if((self[:exit_code] != 0) && !self[:ignore_exit_code])
	  exception_text = self[:error]
	  exception_text = self[:output] if(self[:error].empty?)
	  raise exception_text 
	end
  end
end
