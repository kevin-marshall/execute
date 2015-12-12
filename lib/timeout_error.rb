class TimeoutError < RuntimeError
  def initialize(cmd, seconds)
    @message = "#{cmd} timed out after #{seconds} seconds"
  end
end