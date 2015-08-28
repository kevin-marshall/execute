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
	windows_command(self, self[:command])
  end
  
#  def execute_as(username)
#    raise "Unsupported on operating system #{RbConfig::CONFIG["host_os"]}" unless(RbConfig::CONFIG["host_os"].include?("mingw"))
#    cmd = "runas /noprofile /savecred /user:#{username} \"#{self[:command]}\""
#	wait_on_spawned_process(cmd) { windows_command(self, cmd) }
#  end
  
  private
  def windows_command(hash, cmd)
	begin
	  puts cmd if(hash[:echo_command] || hash[:debug])
		  
	  output = {output: [], error:  [] }
	  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
		{:output => stdout,:error => stderr}.each do |key, stream|
		  Thread.new do
			while wait_thr.alive? do
			  if(!(char = stream.getc).nil?)
  			    output[key] << char
			    putc char if(hash[:echo_output])
			  else
			    sleep(0.1)
			  end
			end
		  end
		end
		
	    # $stdin.gets reads from the console
	    # stdin.puts writes to child process
	    #
	    # while thread.alive? means that we keep on
	    # reading input until the child process ends
        Thread.new do
		  while wait_thr.alive? do
		    begin
              stdin.puts $stdin.gets while wait_thr.alive?
		    rescue Interrupt, Errno::EINTR
              exit(1)
            end
		  end
        end
		
		wait_thr.join
	    hash[:output] = output[:output].join
	    hash[:error] = output[:error].join
		hash[:exit_code] = wait_thr.value.to_i
	  end
	rescue Exception => e
	  hash[:error] = "#{hash[:error]}\nException: #{e.to_s}"
	  hash[:exit_code]=1 unless(hash[:exit_code].nil? || (hash[:exit_code] == 0))
	end
	
	if(hash[:debug])
	  puts "command: #{cmd}" if(hash[:quiet])
	  puts "output: #{hash[:output]}"
	  puts "error: #{hash[:error]}"
	  puts "exit_code: #{hash[:exit_code]}"
	end
	
	if((hash[:exit_code] != 0) && !hash[:ignore_exit_code])
	  exception_text = "Exit code: #{hash[:exit_code]}"
	  exception_text = "#{exception_text}\n#{hash[:error]}"
	  exception_text = "#{exception_text}\n#{hash[:output]}" if(hash[:error].empty?)
	  raise exception_text 
	end
  end
    
  def wait_on_spawned_process(cmd)
	pre_execute = Sys::ProcTable.ps
	
	pre_pids = []
	pre_execute.each { |ps| pre_pids << ps.pid }

    yield	

	match = cmd.match(/\"(?<path>.+\.exe)/i)
	return if(match.nil?)
	
	exe = match[:path]
	exe = File.basename(exe)
	#puts "Exe: #{exe}"
	
	msiexe_pid = 0
 	post_execute = Sys::ProcTable.ps
	post_execute.each do |ps| 
	  msiexe_pid = ps.pid if((ps.name.downcase == exe.downcase) && pre_pids.index(ps.pid).nil?)
	end

	if(msiexe_pid != 0)
	  loop do
	    s = Sys::ProcTable.ps(msiexe_pid)
		break if(s.nil?)
		sleep(1)
	  end
	end  
  end 
end
