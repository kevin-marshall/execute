require 'dev'

task :commit => [:add]

# Yard command line for realtime feed back of Readme.md modifications
# yard server --reload