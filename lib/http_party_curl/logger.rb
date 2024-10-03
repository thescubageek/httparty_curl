# lib/http_party_curl/logger.rb

module HttpPartyCurl
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
        curl_headers = options[:headers] || {}
        curl_body = options[:body]
        curl_query = options[:query]
        curl_basic_auth = options[:basic_auth]
        curl_digest_auth = options[:digest_auth]

        # Append query parameters to URI if present
        if curl_query
          uri = URI(uri)
          existing_query = URI.decode_www_form(uri.query || '')
          new_query = existing_query + curl_query.to_a
          uri.query = URI.encode_www_form(new_query)
          uri = uri.to_s
        end

        curl_command = ["curl -X #{method.to_s.upcase} '#{uri}'"]

        # Add proxy settings to cURL command if present
        if default_options && default_options.values_at(*PROXY_OPTIONS).any? { |opt| !opt.nil? && !opt.to_s.empty? }
          proxy_parts = []
          if default_options[:http_proxyuser] && default_options[:http_proxypass]
            proxy_parts << "#{default_options[:http_proxyuser]}:#{default_options[:http_proxypass]}@"
          end
          proxy_parts << "#{default_options[:http_proxyaddr]}:#{default_options[:http_proxyport]}"
          curl_command << "--proxy 'http://#{proxy_parts.join}'"
        end

        # Add headers to cURL command
        curl_headers.each { |k, v| curl_command << "-H '#{k}: #{v}'" }

        # Add authentication to cURL command
        if curl_basic_auth
          curl_command << "-u '#{curl_basic_auth[:username]}:#{curl_basic_auth[:password]}'"
        elsif curl_digest_auth
          curl_command << "--digest -u '#{curl_digest_auth[:username]}:#{curl_digest_auth[:password]}'"
        end

        # Add body data to cURL command
        unless curl_body.nil?
          content_type = curl_headers['Content-Type'] || curl_headers['content-type']
          if content_type == 'application/x-www-form-urlencoded' && curl_body.is_a?(Hash)
            form_data = URI.encode_www_form(curl_body)
            curl_command << "-d '#{form_data}'"
          elsif content_type == 'multipart/form-data' && curl_body.is_a?(Hash)
            curl_body.each do |key, value|
              if value.respond_to?(:path) && value.respond_to?(:read)
                # File upload
                curl_command << "-F '#{key}=@#{value.path}'"
              else
                curl_command << "-F '#{key}=#{value}'"
              end
            end
          else
            # Default to JSON encoding for hash bodies
            body_data = curl_body.is_a?(String) ? curl_body : curl_body.to_json
            curl_command << "-d '#{body_data}'"
          end
        end

        curl_command.join(" \\\n")
      end

      private

      # Logs the cURL command for the request if logging is enabled.
      #
      # @param method [Symbol] the HTTP method.
      # @param uri [String] the request URI.
      # @param options [Hash] the request options.
      def log_curl(method, uri, options)
        return unless HttpPartyCurl.configuration.curl_logging_enabled

        curl_command = to_curl(method, uri, options)
        HttpPartyCurl.configuration.logger.info("\nHTTParty cURL command:\n#{curl_command}\n")
      end
    end
  end
end
