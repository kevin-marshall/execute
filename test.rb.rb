require 'sys/proctable'

ps = Sys::ProcTable.ps
ps.each { |ps| 
  puts "--------------------------------------------------------------------------"
  puts ps.name
  puts ps.to_s
}
