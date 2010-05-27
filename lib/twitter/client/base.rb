class Twitter::Client
  alias :old_inspect :inspect

  def inspect
    s = old_inspect
    s.gsub!(/@password=".*?"/, '@password="XXXX"')
  end

  protected
    attr_accessor :login, :password
    attr_accessor :oauth_token
    
    # Returns the response of the HTTP connection.  
    def http_connect(body = nil, require_auth = true, service = :rest, &block)
    	require_block(block_given?)
    	connection = create_http_connection(service)
    	connection.start do |connection|
    		request = yield connection if block_given?
    		request.basic_auth(@login, @password) if require_auth && !@login.nil? && !@password.nil?
    		response = connection.request(request, body)
    		handle_rest_response(response)
    		response
      end
    end
    
    # "Blesses" model object with client information
    def bless_model(model)
    	model.bless(self) if model
    end
    
    def bless_models(list)
      return bless_model(list) if list.respond_to?(:client=)
    	list.collect { |model| bless_model(model) } if list.respond_to?(:collect)
    end
    
  private
    @@http_header = nil
    
    def raise_rest_error(response, uri = nil)
      map = JSON.parse(response.body)
      raise Twitter::RESTError.new(:code => response.code, 
                                   :message => response.message,
                                   :error => map["error"],
                                   :uri => uri)        
    end
    
    def handle_rest_response(response, uri = nil)
      unless response.is_a?(Net::HTTPSuccess)
        raise_rest_error(response, uri)
      end
    end
    
    def create_http_connection(service = :rest)
      case service
      when :rest
        protocol, host, port = @@config.protocol, @@config.host, @@config.port
      when :search
        protocol, host, port = @@config.search_protocol, @@config.search_host, @@config.search_port
      end
      conn = Net::HTTP.new(host, port, 
                            @@config.proxy_host, @@config.proxy_port,
                            @@config.proxy_user, @@config.proxy_pass)
      if protocol == :ssl
        conn.use_ssl = true
        conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
     
      # Add timeout from config, if applicable.
      if @@config.timeout
        conn.read_timeout = @@config.timeout
      end

      conn
    end

    def http_header
      # can cache this in class variable since all "variables" used to 
      # create the contents of the HTTP header are determined by other 
      # class variables that are not designed to change after instantiation.
      @@http_header ||= { 
      	'User-Agent' => "Twitter4R v#{Twitter::Version.to_version} [#{@@config.user_agent}]",
      	'Accept' => 'text/x-json',
      	'X-Twitter-Client' => @@config.application_name,
      	'X-Twitter-Client-Version' => @@config.application_version,
      	'X-Twitter-Client-URL' => @@config.application_url,
      }
      @@http_header
    end
    
    def create_http_get_request(uri, params = {})
    	path = (params.size > 0) ? "#{uri}?#{params.to_http_str}" : uri
      Net::HTTP::Get.new(path, http_header)
    end
    
    def create_http_post_request(uri)
    	Net::HTTP::Post.new(uri, http_header)
    end
    
    def create_http_delete_request(uri, params = {})
    	path = (params.size > 0) ? "#{uri}?#{params.to_http_str}" : uri
    	Net::HTTP::Delete.new(path, http_header)
    end

    def http_request(method, path, body = {}, params = {}, service = :rest)

      response = nil
      query = params.to_http_str unless params.blank?

      case service
      when :rest
        protocol, host, port = @@config.protocol, @@config.host, @@config.port
      when :search
        protocol, host, port = @@config.search_protocol, @@config.search_host, @@config.search_port
      end

      if @oauth_token
        # If we have an OAuth::AccessToken passed to the Twitter::Client initializer then all http calls need to go 
        # through the token object and return a Net::HTTPResponse object just like we would get interacting with
        # Net::HTTP directly.

        case protocol
        when :ssl
          builder = URI::HTTPS
        when :http
          builder = URI::HTTP
        end
        
        url = builder.build( :host => host, :port => port, :path => path, :query => query ).to_s
        args = [method, url]
        args << body if [:post, :put].include?(method)
        args << http_header
        response = @oauth_token.send(*args)
      else
        # otherwise we can do a non-authenticated http request directly

        conn = Net::HTTP.new(host, port, 
                              @@config.proxy_host, @@config.proxy_port,
                              @@config.proxy_user, @@config.proxy_pass)
        if protocol == :ssl
          conn.use_ssl = true
          conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
       
        # Add timeout from config, if applicable.
        if @@config.timeout
          conn.read_timeout = @@config.timeout
        end

        path = "#{path}?#{query}" if query

        request = Net::HTTP.const_get(method.to_s.capitalize).new(path, headers)

        if body.is_a?(Hash) && !body.blank?
          request.set_form_data(body)
        elsif body
          request.body = body
        end

        response = conn.request(request)
      end

      response
    end

    def http_get_request(uri, params = {}, service = :rest)
      http_request(:get, uri, nil, params, service)
    end

    def http_post_request(uri, body, params = {}, service = :rest)
      http_request(:post, uri, body, params, service)
    end

    def http_delete_request(uri, params = {}, service = :rest)
      http_request(:delete, uri, nil, params, service)
    end
end
