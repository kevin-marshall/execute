filename='file.txt'
filename=ARGV[0] if(ARGV.size == 1)
File.open(filename,'w') {|f| f.puts("Created: #{Time.now.to_s}") }
