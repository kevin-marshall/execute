require 'open3'
require 'sys/proctable'
require_relative 'timeout_error.rb'

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
    if(self[:quiet])
	  self[:echo_output] = false
	  self[:echo_command] = false
	end
	
	puts self[:command] if(self[:echo_command] || self[:debug])
	system  
    	
	if(self[:debug])
	  puts "command: #{self[:command]}"
	  puts "output: #{self[:output]}"
	  puts "error: #{self[:error]}"
	  puts "exit_code: #{self[:exit_code]}"
	end
	
	raise TimeoutError.new(self[:command], self[:timeout]) if(key?(:timed_out))
	if((self[:exit_code] != 0) && !self[:ignore_exit_code])
	  exception_text = "Exit code: #{self[:exit_code]}"
	  exception_text = "#{exception_text}\nError: '#{self[:error]}'"
	  exception_text = "#{exception_text}\nOutput: '#{self[:output]}'"
	  raise StandardError.new(exception_text) 
	end
  end

  def system
	begin
      output = ''
	  error = ''  
	  Thread.abort_on_exception = true
	  mutex = Mutex.new
	  
	  Open3.popen3(self[:command]) do |stdin, stdout, stderr, wait_thr|
        self[:pid] = wait_thr.pid 
		
		if(key?(:timeout))
		  start_time = Time.now
		  Thread.new do
		    while wait_thr.alive? do
 		      sleep(0.1)
			  if((Time.now - start_time).to_f > self[:timeout])
				self[:timed_out] = true
				Process.kill('KILL',wait_thr.pid)
				sleep(0.1)
			  end
			end
		  end
        end
		
  	    {:output => stdout,:error => stderr}.each do |key, stream|
          Thread.new do			    
		    while wait_thr.alive? && !key?(:timed_out) do
		      if(!(char = stream.getc).nil?)
			    case key
			      when :output
			        output << char
			      when :error
			        error << char
			    end

			    mutex.synchronize { putc char if(self[:echo_output]) }
		      else
		        sleep(0.1)
			  end
	        end
		  end
		end

		wait_thr.join

	    self[:output] = output unless(output.empty?)			    
		self[:error] = error unless(error.empty?)
		self[:exit_code] = wait_thr.value.to_i		
	  end
	rescue Exception => e
	  self[:error] = "#{self[:error]}\nException: #{e.to_s}"
	  self[:exit_code]=1 unless(self[:exit_code].nil? || (self[:exit_code] == 0))
	rescue => e
	  self[:error] = "#{self[:error]}\nException: #{e.to_s}"
	  self[:exit_code]=1 unless(self[:exit_code].nil? || (self[:exit_code] == 0))
	end
  end
  # Open3.capture3 hung on runas
end
