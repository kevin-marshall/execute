class TimeoutError < StandardError
  def initialize(cmd, seconds)
    @message = "#{cmd} timed out after #{seconds} seconds"
  end
end