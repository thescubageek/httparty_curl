# lib/httparty_curl/logger.rb

module HTTPartyCurl
  # Module containing the cURL logging functionality.
  module Logger
    # List of proxy options to consider.
    PROXY_OPTIONS = %i[http_proxyaddr http_proxyport http_proxyuser http_proxypass].freeze

    # Hook method called when the module is included.
    # Extends the base class with class methods.
    # @param base [Class] the class including the module.
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Class methods added to the including class.
    module ClassMethods
      # List of HTTP methods to override with logging functionality.
      HTTP_METHODS = %i[get post put patch delete].freeze

      # Dynamically defines overridden HTTP methods.
      HTTP_METHODS.each do |http_method|
        define_method(http_method) do |uri, options = {}, &block|
          options ||= {}
          log_curl(http_method, uri, options)
          super(uri, options, &block)
        end
      end

      # Converts an HTTParty request to a cURL command.
      #
      # @param method [Symbol] the HTTP method (e.g., :get, :post).
      # @param uri [String] the request URI.
      # @param options [Hash] the request options (headers, body, etc.).
      # @return [String] the generated cURL command.
      def to_curl(method, uri, options = {})
        options ||= {}

        # Prepare the URI and append query parameters if present
        uri = prepare_uri(uri, options[:query])

        curl_command = initialize_curl_command(method, uri)

        # Add proxy settings if available
        add_proxy_settings(curl_command)

        # Add headers to the cURL command
        add_headers(curl_command, options[:headers])

        # Add authentication to the cURL command
        add_authentication(curl_command, options[:basic_auth], options[:digest_auth])

        # Add body data to the cURL command
        add_body_data(curl_command, options[:body], options[:headers])

        curl_command.join(" \\\n")
      end

      private

      # Prepares the full URI, including base_uri and query parameters.
      #
      # @param uri [String] the request URI.
      # @param query [Hash, nil] the query parameters.
      # @return [String] the full URI with query parameters.
      def prepare_uri(uri, query)
        # Ensure base_uri is included if it's a relative path
        unless uri.start_with?('http')
          effective_base_uri = self.base_uri || 'http://localhost' #  rubocop:disable Style/RedundantSelf
          uri = URI.join(effective_base_uri, uri).to_s
        end

        # Append query parameters to URI if present
        if query
          uri = URI(uri)
          existing_query = URI.decode_www_form(uri.query || '')
          new_query = existing_query + query.to_a
          uri.query = URI.encode_www_form(new_query)
          uri = uri.to_s
        end

        uri
      end

      # Initializes the cURL command with the HTTP method and URI.
      #
      # @param method [Symbol] the HTTP method.
      # @param uri [String] the full request URI.
      # @return [Array<String>] the initial cURL command array.
      def initialize_curl_command(method, uri)
        ["curl -X #{method.to_s.upcase} '#{uri}'"]
      end

      # Adds proxy settings to the cURL command if present.
      #
      # @param curl_command [Array<String>] the cURL command array.
      def add_proxy_settings(curl_command)
        if default_options && default_options.values_at(*PROXY_OPTIONS).any? { |opt| !opt.nil? && !opt.to_s.empty? }
          proxy_parts = []
          if default_options[:http_proxyuser] && default_options[:http_proxypass]
            proxy_parts << "#{default_options[:http_proxyuser]}:#{default_options[:http_proxypass]}@"
          end
          proxy_parts << "#{default_options[:http_proxyaddr]}:#{default_options[:http_proxyport]}"
          curl_command << "--proxy 'http://#{proxy_parts.join}'"
        end
      end

      # Adds headers to the cURL command.
      #
      # @param curl_command [Array<String>] the cURL command array.
      # @param headers [Hash, nil] the request headers.
      def add_headers(curl_command, headers)
        (headers || {}).each do |k, v|
          curl_command << "-H '#{k}: #{v}'"
        end
      end

      # Adds authentication options to the cURL command.
      #
      # @param curl_command [Array<String>] the cURL command array.
      # @param basic_auth [Hash, nil] the basic authentication credentials.
      # @param digest_auth [Hash, nil] the digest authentication credentials.
      def add_authentication(curl_command, basic_auth, digest_auth)
        if basic_auth
          curl_command << "-u '#{basic_auth[:username]}:#{basic_auth[:password]}'"
        elsif digest_auth
          curl_command << "--digest -u '#{digest_auth[:username]}:#{digest_auth[:password]}'"
        end
      end

      # Adds body data to the cURL command.
      #
      # @param curl_command [Array<String>] the cURL command array.
      # @param body [String, Hash, nil] the request body.
      # @param headers [Hash, nil] the request headers.
      # rubocop:disable Metrics/CyclomaticComplexity
      def add_body_data(curl_command, body, headers)
        return if body.nil?

        headers ||= {}
        content_type = headers['Content-Type'] || headers['content-type']

        if content_type == 'application/x-www-form-urlencoded' && body.is_a?(Hash)
          form_data = URI.encode_www_form(body)
          curl_command << "-d '#{form_data}'"
        elsif content_type == 'multipart/form-data' && body.is_a?(Hash)
          body.each do |key, value|
            if value.respond_to?(:path) && value.respond_to?(:read)
              # File upload
              curl_command << "-F '#{key}=@#{value.path}'"
            else
              curl_command << "-F '#{key}=#{value}'"
            end
          end
        else
          # Default to JSON encoding for hash bodies
          body_data = body.is_a?(String) ? body : body.to_json
          curl_command << "-d '#{body_data}'"
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      # Logs the cURL command for the request if logging is enabled.
      #
      # @param method [Symbol] the HTTP method.
      # @param uri [String] the request URI.
      # @param options [Hash] the request options.
      def log_curl(method, uri, options)
        return unless HTTPartyCurl.configuration.curl_logging_enabled

        curl_command = to_curl(method, uri, options)
        HTTPartyCurl.configuration.logger.info("\nHTTParty cURL command:\n#{curl_command}\n")
      end
    end
  end
end
