# test/httparty_curl_test.rb

require 'minitest/autorun'
require 'httparty_curl'
require 'stringio'

class HTTPartyCurlTest < Minitest::Test
  def setup
    # Reset the configuration before each test
    HTTPartyCurl.configuration = nil
    @original_rails = nil
  end

  def teardown
    # Reset the configuration after each test
    HTTPartyCurl.configuration = nil
    restore_rails_constant
  end

  # Helper method to simulate a Rails environment
  def simulate_rails_environment(env)
    # Save the original Rails constant if it exists
    @original_rails = Object.const_get(:Rails) if defined?(Rails)

    # Create a mock Rails object with the specified environment
    rails_mock = Minitest::Mock.new
    rails_mock.expect(:env, env)

    # Set the Rails constant to the mock
    Object.const_set(:Rails, rails_mock)
  end

  # Helper method to remove the Rails constant if it exists
  def remove_rails_constant
    if defined?(Rails)
      @original_rails = Object.const_get(:Rails)
      Object.send(:remove_const, :Rails)
    end
  end

  # Helper method to restore the original Rails constant
  def restore_rails_constant
    if @original_rails
      Object.const_set(:Rails, @original_rails)
      @original_rails = nil
    else
      Object.send(:remove_const, :Rails) if defined?(Rails)
    end
  end

  def test_configuration_defaults_in_production_environment
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new

    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled
    assert_instance_of ::Logger, configuration.logger
    assert_equal $stdout, configuration.logger.instance_variable_get(:@logdev).dev
  end

  def test_configuration_defaults_in_development_environment
    simulate_rails_environment('development')

    configuration = HTTPartyCurl::Configuration.new

    assert_equal :development, configuration.environment
    assert configuration.curl_logging_enabled
    assert_instance_of ::Logger, configuration.logger
  end

  def test_configuration_defaults_in_test_environment
    simulate_rails_environment('test')

    configuration = HTTPartyCurl::Configuration.new

    assert_equal :test, configuration.environment
    assert configuration.curl_logging_enabled
    assert_instance_of ::Logger, configuration.logger
  end

  def test_configuration_defaults_in_other_rails_environment
    simulate_rails_environment('staging')

    configuration = HTTPartyCurl::Configuration.new

    assert_equal :staging, configuration.environment
    refute configuration.curl_logging_enabled
  end

  def test_configuration_can_set_curl_logging_enabled
    remove_rails_constant

    HTTPartyCurl.configure do |config|
      config.curl_logging_enabled = true
    end

    assert HTTPartyCurl.configuration.curl_logging_enabled
  end

  def test_configuration_can_set_logger
    custom_logger = Logger.new(StringIO.new)

    HTTPartyCurl.configure do |config|
      config.logger = custom_logger
    end

    assert_equal custom_logger, HTTPartyCurl.configuration.logger
  end

  def test_configuration_environment_can_be_set_in_non_rails_app
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    configuration.environment = :development

    assert_equal :development, configuration.environment
    assert configuration.curl_logging_enabled
  end

  def test_configuration_default_environment_in_non_rails_app
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new

    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled
  end

  def test_error_class_exists
    assert_kind_of Class, HTTPartyCurl::Error
    assert HTTPartyCurl::Error < StandardError
  end

  def test_configure_block_sets_configuration
    custom_logger = Logger.new(StringIO.new)

    HTTPartyCurl.configure do |config|
      config.curl_logging_enabled = true
      config.logger = custom_logger
      config.environment = :test
    end

    assert HTTPartyCurl.configuration.curl_logging_enabled
    assert_equal custom_logger, HTTPartyCurl.configuration.logger
    assert_equal :test, HTTPartyCurl.configuration.environment
  end

  def test_configuration_respects_environment_change
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled

    configuration.environment = :development
    assert_equal :development, configuration.environment
    assert configuration.curl_logging_enabled
  end

  def test_environment_setter_updates_environment
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled

    configuration.environment = :development
    assert_equal :development, configuration.environment
  end

  def test_environment_setter_updates_curl_logging_enabled
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled

    configuration.environment = :development
    assert_equal :development, configuration.environment
    assert configuration.curl_logging_enabled

    configuration.environment = :test
    assert_equal :test, configuration.environment
    assert configuration.curl_logging_enabled

    configuration.environment = :production
    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled

    configuration.environment = :staging
    assert_equal :staging, configuration.environment
    refute configuration.curl_logging_enabled
  end

  def test_environment_setter_with_string_argument
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    configuration.environment = 'development'
    assert_equal :development, configuration.environment
    # Assuming default_logging_enabled? handles strings
    assert configuration.curl_logging_enabled
  end

  def test_environment_setter_with_invalid_argument
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    configuration.environment = nil
    assert_nil configuration.environment
    refute configuration.curl_logging_enabled
  end

  def test_environment_setter_does_not_affect_logger
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    original_logger = configuration.logger

    configuration.environment = :development
    assert_equal original_logger, configuration.logger
  end

  def test_environment_setter_updates_curl_logging_enabled_correctly
    remove_rails_constant

    configuration = HTTPartyCurl::Configuration.new
    configuration.curl_logging_enabled = false

    configuration.environment = :development
    assert_equal :development, configuration.environment
    # Since environment changed, curl_logging_enabled should be updated
    assert configuration.curl_logging_enabled

    # Manually disable logging again
    configuration.curl_logging_enabled = false
    configuration.environment = :production
    assert_equal :production, configuration.environment
    refute configuration.curl_logging_enabled
  end
end
