require "net/http"

# Turns on Net::HTTP debugging globally so that you know whatever underlying
# library is accessing network and what it does.
module Net
  class HTTP < Protocol
    private
    
    def D(msg)
      @debug_output ||= STDERR
      @debug_output << msg
      @debug_output << "\n"
    end
  end
end