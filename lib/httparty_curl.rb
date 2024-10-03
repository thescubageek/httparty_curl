# lib/httparty_curl.rb

require 'httparty'
require 'httparty_curl/version'
require 'logger'
require 'json'

# Main module for the HTTPartyCurl gem.
# Provides functionality to log HTTParty requests as cURL commands.
module HTTPartyCurl
  # Custom error class for the gem.
  class Error < StandardError; end

  # Configuration class to store gem settings.
  class Configuration
    attr_accessor :curl_logging_enabled, :logger
    attr_reader :environment

    def initialize
      @environment = detect_environment
      @curl_logging_enabled = default_logging_enabled?
      @logger = ::Logger.new($stdout)
    end

    # Sets the environment
    #
    # @param env [tring|Symbol] environment
    def environment=(env)
      @environment = env&.to_sym
      @curl_logging_enabled = default_logging_enabled?
    end

    private

    # Detects the environment or sets it to :production by default
    def detect_environment
      if defined?(Rails)
        Rails.env.to_sym
      else
        # Default to :production for non-Rails applications
        :production
      end
    end

    # Determines if logging should be enabled by default
    def default_logging_enabled?
      %i[development test].include?(@environment)
    end
  end

  class << self
    # @return [Configuration] the current configuration instance.
    attr_accessor :configuration

    # Configures the gem settings.
    # @yieldparam config [Configuration] the configuration object to set options.
    # @example
    #   HTTPartyCurl.configure do |config|
    #     config.curl_logging_enabled = true
    #     config.logger = Logger.new('log/httparty_curl.log')
    #   end
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end

  # Load the Logger module containing the cURL logging functionality.
  require_relative 'httparty_curl/logger'
end
