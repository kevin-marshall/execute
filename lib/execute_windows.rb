require 'open3'
require 'sys/proctable'
require_relative 'execute'

class Execute < Hash
  def execute_as(username)
    self[:command] = "runas /noprofile /savecred /user:#{username} \"#{self[:command]}\""
	wait_on_spawned_process(self) { self.execute }
  end
  
  private
  def wait_on_spawned_process(cmd)
	yield	
	post_execute = Sys::ProcTable.ps
	
	child_processes = []
    post_execute.each { |ps| child_processes << ps.pid if(ps.include?(cmd[:pid])) }
	
	trap("INT") do 
	  child_processes.each do |pid|
	    s = Sys::ProcTable.ps(pid)
        begin
          if(!s.nil?)
		    out_rd,out_wr = IO.pipe
			err_rd,err_wr = IO.pipe
			system("taskkill /pid #{pid}", :out => out_wr, :err => err_wr)
		  end
		rescue => e
		end
	  end
	  exit
	end
	
	loop do
	  all_exited = true
	  child_processes.each do |pid|
	    s = Sys::ProcTable.ps(pid)
		all_exited = false unless(s.nil?)
	  end
	  break if(all_exited)
	  sleep(0.2)
	end
  end
end
