require "uri"
require "cgi"
require "openssl"

module OAuthClient
  # See OAuth 1.0 RFC spec.
  # http://tools.ietf.org/html/rfc5849

  class Token
    attr_accessor :token, :secret

    def initialize(token, secret)
      @token, @secret = token, secret
    end

    alias :key :token
  end

  class Parameters
    def initialize(*params_list)
      @params = {}
      self.update(*params_list)
    end

    def update(*params_list)
      params_list.each do |params|
        params = case params
        when String
          params_from_urlencoded_string(params)
        when Hash
          params
        else
          next
        end

        params.each do |key, value|
          key = key.to_sym
          value = Array === value ? value : [value]
          if @params[key]
            @params[key].concat(value)
          else
            @params[key] = value
          end
        end
      end

      self
    end

    def to_hash
      @params.dup
    end

    private

    def params_from_urlencoded_string(query)
      query.to_s.split("&").inject({}) do |parameters, key_and_value|
        key, value = key_and_value.split("=", 2).map{|v| CGI.unescape(v)}
        key = key.to_sym
        if parameters[key]
          parameters[key] << value
        else
          parameters[key] = [value]
        end
        parameters
      end
    end
  end

  class Request
    CONTENT_TYPE = "Content-Type".freeze
    X_WWW_FORM_URLENCODED = "application/x-www-form-urlencoded".freeze

    class << self
      def create_from_net_http_request(http, request)
        method = request.method
        scheme = http.use_ssl? ? "https" : "http"

        uri = URI.parse(request.path)
        params = [uri.query]
        if request[CONTENT_TYPE] == X_WWW_FORM_URLENCODED
          params << request.body
        end

        new(:method => method,
          :scheme => scheme, :host => http.address, :path => uri.path,
          :params => params.compact)
      end

      def create_from_typhoeus_request(request)
        method = request.method
        uri = URI.parse(request.url)
        params = if method == :post
          # NOTE is this good?
          if request.headers[CONTENT_TYPE] == X_WWW_FORM_URLENCODED
            request.body
          else
            request.params_string
          end
        end
        new(:method => method, :uri => uri, :params => params)
      end

      def create_from_uri(method, uri, params = nil)
        new(:method => method, :uri => uri, :params => params)
      end
    end

    attr_reader :host, :path, :params

    def initialize(options)
      @method = options[:method] || "GET"
      @params = Parameters.new(*options[:params])

      if uri = options[:uri]
        @scheme = uri.scheme
        @host = uri.host
        @path = uri.path
        @port = uri.port
        @params.update(uri.query)
      else
        @scheme = options[:scheme] || "http"
        @host = options[:host] or raise "Missing :host option."
        @path = options[:path] || ""
        @port = options[:port] || 80
      end
    end

    def method
      @method.to_s.upcase
    end

    def uri
      @uri ||= "#{scheme}://#{host}#{port_string}#{path}"
    end

    private

    def scheme
      @scheme.to_s.downcase
    end

    def port_string
      if (scheme == "http" && @port == 80) || (scheme == "https" && @port == 443)
        ""
      else
        ":#{@port}"
      end
    end
  end

  class Signature
    attr_reader :consumer, :access_token

    def initialize(request, consumer, access_token = nil)
      @request = request
      @consumer = consumer
      @access_token = access_token
    end

    def auth_params
      @auth_params ||= oauth_params.merge({
        :oauth_signature => oauth_signature
      })
    end

    def auth_header(realm = nil)
      @auth_header ||= "OAuth ".tap do |header|
        header << %{realm="#{realm}", } if realm
        header << auth_params.map{|key, value| %{#{encode(key)}="#{encode(value)}"}}.join(", ")
      end
    end

    private

    def request_params
      @request_params ||= @request.params.to_hash.merge(oauth_params)
    end

    def oauth_params
      @oauth_params ||= {
        :oauth_version => "1.0",
        :oauth_signature_method => "HMAC-SHA1",
        :oauth_timestamp => timestamp,
        :oauth_nonce => nonce,
        :oauth_consumer_key => consumer.key
      }.tap do |params|
        params[:oauth_token] = access_token.token if access_token
      end
    end

    def timestamp
      Time.now.utc.to_i.to_s
    end

    def nonce
      base64_encode OpenSSL::Random.random_bytes(32)
    end

    def oauth_signature
      base64_encode OpenSSL::HMAC.digest(sha1_digest, secret, base_string)
    end

    def sha1_digest
      OpenSSL::Digest::Digest.new('sha1')
    end

    def secret
      [consumer.secret, access_token ? access_token.secret : nil].join("&")
    end

    def base_string
      [@request.method, @request.uri, params_string].map{|v| encode(v)}.join("&")
    end

    def params_string
      encoded_params = {}

      request_params.each do |key, values|
        key = encode(key)
        values = Array(values).map{|value| encode(value)}
        encoded_params[key] = values
      end

      encoded_params.sort.map do |key, values|
        values.sort.map{|value| [key, value].join("=")}
      end.flatten.join("&")
    end

    def base64_encode(data)
      [data].pack("m").gsub(/\n/, '')
    end

    UNRESERVED_CHARACTERS = /[^0-9a-zA-Z\-._~]/

    # OAuth RFC document is using a word 'encode' instead of escape.
    def encode(value)
      URI.escape(value.to_s, UNRESERVED_CHARACTERS)
    end
  end
end
