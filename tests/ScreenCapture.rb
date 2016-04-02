require 'win32/screenshot'

puts "ARGV: #{ARGV[0]}"
FileUtils.mkpath(File.dirname(ARGV[0])) unless(Dir.exists?(File.dirname(ARGV[0])))
Win32::Screenshot::Take.of(:foreground).write('screen_capture.png')