require 'open3'
require 'sys/proctable'

class CMD < Hash
  private 
  @@default_options = { echo_command: true, echo_output: true, ignore_exit_code: false, debug: false }
  
  public
  def initialize(cmd, options=nil)
   initialize_defaults if(@@default_options.nil?)
   self[:output] = ''
   self[:error] = ''
   
   @@default_options.each { |key, value| self[key] = value}
   options.each { |key, value| self[key] = value} unless(options.nil?)
   self[:command]=cmd
  end
  
  public
  def self.default_options(hash)
	hash.each { |key, value| @@default_options[key] = value}
  end

  def execute
	puts self[:command] if(self[:echo_command] || self[:debug])
	system  
    	
	if(self[:debug])
	  puts "command: #{self[:command]}" if(self[:quiet])
	  puts "output: #{self[:output]}"
	  puts "error: #{self[:error]}"
	  puts "exit_code: #{self[:exit_code]}"
	end
	
	if((self[:exit_code] != 0) && !self[:ignore_exit_code])
	  exception_text = "Exit code: #{self[:exit_code]}"
	  exception_text = "#{exception_text}\nError: '#{self[:error]}'"
	  exception_text = "#{exception_text}\nOutput: '#{self[:output]}'"
	  raise Exception.new(exception_text) 
	end
  end

  def system
	begin
      output = {output: [], error: [] }
	  Open3.popen3(self[:command]) do |stdin, stdout, stderr, wait_thr|
        self[:pid] = wait_thr.pid 
  	    {:output => stdout,:error => stderr}.each do |key, stream|
          Thread.new do
	        while wait_thr.alive? do
		      if(!(char = stream.getc).nil?)
		        output[key] << char
			    putc char if(self[:echo_output])
		      else
		        sleep(0.1)
			  end
	        end
		  end
		end

		wait_thr.join

	    self[:output] = output[:output].join unless(output[:output].empty?)
	    self[:error] = output[:error].join unless(output[:error].empty?)
		self[:exit_code] = wait_thr.value.to_i
	  end
	rescue Exception => e
	  self[:error] = "#{self[:error]}\nException: #{e.to_s}"
	  self[:exit_code]=1 unless(self[:exit_code].nil? || (self[:exit_code] == 0))
	end
  end
  # Open3.capture3 hung on runas
end
