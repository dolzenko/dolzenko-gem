require "net/http"

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