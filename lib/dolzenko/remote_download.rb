module RemoteDownload
  # Returns IO object to be used with attachment_fu models, if retrieval fails - return nil
  def get_uploaded_data(url, follow_redirect = 2)
    uri = URI.parse(url)
    
    dputs(%{Trying to retrieve image from #{ uri } })

    response = nil
    Net::HTTP.start(uri.host, uri.port) do |http|
      # http.set_debug_output $stderr
      dputs(%{In Net::HTTP.start})
      
      response = http.request_get(uri.path + (uri.query ? "?" + uri.query : ""), {
              "User-Agent" => "curl/7.14.0 (i586-pc-mingw32msvc) libcurl/7.14.0 zlib/1.2.2",
              "Host" => uri.host,
              "Accept" => "*/*",
              "Referer" => SELFPORT,
              })
      
      dputs("got response: #{ response }")
    end

    case response
      when Net::HTTPSuccess
        MyStringIO.from_http_response(response, url)

      when Net::HTTPRedirection
        return nil if follow_redirect <= 0

        defined?(logger) && logger.debug(%{Following redirect from #{uri} to #{response['location']}})

        get_uploaded_data(response['location'], follow_redirect - 1)
      
      else
        nil
    end
  end
  module_function :get_uploaded_data

  # Returns page content, if retrieval failed - just return empty string
  def download_page(url, follow_redirect = 2)
    uri = URI.parse(url)

    defined?(logger) && logger.debug(%{Trying to retrieve page #{uri}})

    response = nil
    Net::HTTP.start(uri.host, uri.port) do |http|
      response = http.request_get(uri.path + (uri.query ? "?" + uri.query : ""), {
              "User-Agent" => "curl/7.14.0 (i586-pc-mingw32msvc) libcurl/7.14.0 zlib/1.2.2",
              "Host" => uri.host,
              "Accept" => "text/html",
              "Referer" => SELFPORT,
              }
      )
    end

    case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        return "" if follow_redirect <= 0

        defined?(logger) && logger.debug(%{Following redirect from #{uri} to #{response['location']}})

        download_page(response['location'], follow_redirect - 1)
      else
        ""
    end
  end

  module_function :download_page

  class MyStringIO < StringIO
    def initialize(*args)
      super(*args)
    end

    # Constructs IO object from HTTPResponse
    def self.from_http_response(response, request_url)
      new(response.body).tap do |io|
        io.size = response.body.size
        io.content_type = response['content-type']
        io.filename = File.basename(request_url)
        io.original_filename = File.basename(request_url)
      end
    end

    attr_accessor :content_type, :filename, :size, :original_filename
  end
end