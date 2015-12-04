require 'timeout'

begin
Timeout::timeout(30) do
loop do
  puts "Running..."
  File.open('C:/Development/wrk/github/execute/trac.log', 'a') { |f| f.puts "Hello, world #{Time.now}" }
  sleep(1)
end
end
rescue => e
end