# lib/http_party_curl.rb

require 'httparty'
require 'http_party_curl/version'
require 'logger'
require 'json'

# Main module for the HttpPartyCurl gem.
# Provides functionality to log HTTParty requests as cURL commands.
module HttpPartyCurl
  # Custom error class for the gem.
  class Error < StandardError; end

  # Configuration class to store gem settings.
  class Configuration
    # @return [Boolean] whether cURL logging is enabled.
    attr_accessor :curl_logging_enabled

    # @return [Logger] the logger instance used for logging.
    attr_accessor :logger

    # Initializes the configuration with default values.
    def initialize
      @curl_logging_enabled = false
      @logger = ::Logger.new($stdout)
    end
  end

  class << self
    # @return [Configuration] the current configuration instance.
    attr_accessor :configuration

    # Configures the gem settings.
    # @yieldparam config [Configuration] the configuration object to set options.
    # @example
    #   HttpPartyCurl.configure do |config|
    #     config.curl_logging_enabled = true
    #     config.logger = Logger.new('log/httparty_curl.log')
    #   end
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end

  # Load the Logger module containing the cURL logging functionality.
  require_relative 'http_party_curl/logger'
end
