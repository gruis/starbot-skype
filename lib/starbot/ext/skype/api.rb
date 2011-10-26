require 'logger'
module Skype
  class Api
    attr_accessor :verbose
    
    private
    
    def log_incoming(message)
      STDERR.puts "<- #{message}" if verbose == Logger::DEBUG
    end
    
    def log_outgoing(message)
      STDERR.puts "-> #{message}" if verbose == Logger::DEBUG
    end
  end # class::Api
end # module::Skype
