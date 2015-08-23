require 'open3'
require 'sys/proctable'
require_relative 'IOAdapter.rb'

class CMD < Hash
  private 
  @@default_options = nil
  
  def self.initialize_defaults
    @@default_options = { echo_command: true, echo_output: true, ignore_exit_code: false, debug: false }
  end

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
    initialize_defaults
	hash.each { |key, value| @@default_options[key] = value}
  end
  
  def execute
    #begin
	  puts self[:command] if(self[:echo_command])
	
	  output = {output: [], error:  [] }
	  Open3.popen3(self[:command]) do |stdin, stdout, stderr, wait_thr|
		{:output => stdout,:error => stderr}.each do |key, stream|
		  Thread.new do
			until(raw_line = stream.gets).nil? do
			  output[key] << raw_line
			  puts raw_line if(self[:echo_output])
			end
		  end
		end
		wait_thr.join
	    self[:output] = output[:output].join
	    self[:error] = output[:error].join
		self[:exit_code] = wait_thr.value.to_i
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
