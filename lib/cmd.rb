require 'open3'
require 'sys/proctable'
require 'timeout'

class CMD < Hash
  private 
  @@default_options = { echo_command: true, echo_output: true, ignore_exit_code: false, debug: false }
  
  public
  def initialize(cmd, options=nil)
   initialize_defaults if(@@default_options.nil?)
   self[:output] = ''
   self[:error] = ''
   
   #1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL
   #5) SIGTRAP      6) SIGABRT      7) SIGBUS       8) SIGFPE
   #9) SIGKILL     10) SIGUSR1     11) SIGSEGV     12) SIGUSR2
   #13) SIGPIPE     14) SIGALRM     15) SIGTERM     17) SIGCHLD
   #18) SIGCONT     19) SIGSTOP     20) SIGTSTP     21) SIGTTIN
   #22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
   #26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO
   #30) SIGPWR      31) SIGSYS      34) SIGRTMIN    35) SIGRTMIN+1
   #36) SIGRTMIN+2  37) SIGRTMIN+3  38) SIGRTMIN+4  39) SIGRTMIN+5
   #40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8  43) SIGRTMIN+9
   #44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
   #48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13
   #52) SIGRTMAX-12 53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9
   #56) SIGRTMAX-8  57) SIGRTMAX-7  58) SIGRTMAX-6  59) SIGRTMAX-5
   #60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2  63) SIGRTMAX-1
   #64) SIGRTMAX
   self[:timeout_signal] = 2
   self[:timeout_raise_error] = true
   
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
	
	raise TimeoutError.new("Commnad '#{self[:command]}' timed out after #{self[:timeout]} seconds") if(key?(:timed_out) && self[:timeout_raise_error])

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
				interrupt
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
					putc char if(self[:echo_output])
			      when :error
			        error << char
			    end
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
	end
  end
  def interrupt
    process = get_child_processes(self[:pid])
	Sys::ProcTable.ps { |p| process << p  if(p.pid == self[:pid]) }

	process.each { |p| Process.kill(self[:timeout_signal],p.pid) unless(Sys::ProcTable.ps(p.pid).nil?) }
	Process.waitpid(self[:pid]) unless(Sys::ProcTable.ps(self[:pid]).nil?) 
  end
  def get_child_processes(pid)
	processes = []
	Sys::ProcTable.ps do |p| 
	  if(p.ppid == pid) 
		get_child_processes(p.pid).each { |cp| processes << cp }
		processes << p
	  end
	end
	return processes
  end
end
