require 'securerandom'
require 'tempfile'
class IOAdapter < DelegateClass(IO)
  attr_accessor :output_buffer
  def initialize(io)
    __setobj__(io)
	@output_buffer = []
  end
  
  def write(string)
	@output_buffer << string
	self.__getobj__.write(string)
  end
end