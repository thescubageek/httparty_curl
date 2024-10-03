# test/http_party_curl_test.rb

require 'minitest/autorun'
require 'httparty'
require 'http_party_curl'
require 'stringio'

class HttpPartyCurlTest < Minitest::Test
  def setup
    # Configure the gem for testing
    HttpPartyCurl.configure do |config|
      config.curl_logging_enabled = true
      config.logger = Logger.new(StringIO.new) # Use StringIO to capture logger output
    end

    # Create a dynamic client class for testing
    @client_class = Class.new do
      include HTTParty
      include HttpPartyCurl::Logger

      base_uri 'http://example.com'
    end
  end

  def teardown
    # Reset the configuration after each test
    HttpPartyCurl.configuration = HttpPartyCurl::Configuration.new
  end

  def test_get_request_logs_curl_command
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil) do |message|
      message.include?("curl -X GET 'http://example.com/'")
    end

    HttpPartyCurl.configuration.logger = mock_logger

    @client_class.get('/')

    mock_logger.verify
  end

  def test_post_request_with_body
    body = { 'key' => 'value' }
    expected_curl = "curl -X POST 'http://example.com/' \\\n-d '#{body.to_json}'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.post('/', body: body)

    assert_includes captured_output.string, expected_curl
  end

  def test_request_with_headers
    headers = { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer token' }
    expected_curl = "-H 'Content-Type: application/json' \\\n-H 'Authorization: Bearer token'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/', headers: headers)

    assert_includes captured_output.string, expected_curl
  end

  def test_request_with_query_params
    query = { 'param1' => 'value1', 'param2' => 'value2' }
    expected_uri = "http://example.com/?param1=value1&param2=value2"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/', query: query)

    assert_includes captured_output.string, "curl -X GET '#{expected_uri}'"
  end

  def test_request_with_basic_auth
    auth = { username: 'user', password: 'pass' }
    expected_curl = "-u 'user:pass'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/', basic_auth: auth)

    assert_includes captured_output.string, expected_curl
  end

  def test_request_with_digest_auth
    auth = { username: 'user', password: 'pass' }
    expected_curl = "--digest -u 'user:pass'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/', digest_auth: auth)

    assert_includes captured_output.string, expected_curl
  end

  def test_post_request_with_form_data
    body = { 'key1' => 'value1', 'key2' => 'value2' }
    headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    expected_data = "key1=value1&key2=value2"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.post('/', headers: headers, body: body)

    assert_includes captured_output.string, "-d '#{expected_data}'"
  end

  def test_post_request_with_multipart_form_data
    file = File.open(__FILE__)
    body = { 'file' => file, 'key' => 'value' }
    headers = { 'Content-Type' => 'multipart/form-data' }

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.post('/', headers: headers, body: body)

    assert_includes captured_output.string, "-F 'file=@#{file.path}'"
    assert_includes captured_output.string, "-F 'key=value'"

    file.close
  end

  def test_request_with_proxy_settings
    @client_class.http_proxy('proxy.example.com', 8080, 'proxyuser', 'proxypass')
    expected_proxy = "--proxy 'http://proxyuser:proxypass@proxy.example.com:8080'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/')

    assert_includes captured_output.string, expected_proxy
  end

  def test_logging_disabled
    HttpPartyCurl.configuration.curl_logging_enabled = false
    mock_logger = Minitest::Mock.new
    mock_logger.expect(:info, nil).never

    HttpPartyCurl.configuration.logger = mock_logger

    @client_class.get('/')

    mock_logger.verify
  end

  def test_custom_logger
    captured_output = StringIO.new
    custom_logger = Logger.new(captured_output)

    HttpPartyCurl.configuration.logger = custom_logger

    @client_class.get('/')

    assert_includes captured_output.string, "curl -X GET 'http://example.com/'"
  end

  def test_put_request
    body = { 'update' => 'data' }
    expected_curl = "curl -X PUT 'http://example.com/' \\\n-d '#{body.to_json}'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.put('/', body: body)

    assert_includes captured_output.string, expected_curl
  end

  def test_patch_request
    body = { 'patch' => 'data' }
    expected_curl = "curl -X PATCH 'http://example.com/' \\\n-d '#{body.to_json}'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.patch('/', body: body)

    assert_includes captured_output.string, expected_curl
  end

  def test_delete_request
    expected_curl = "curl -X DELETE 'http://example.com/'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.delete('/')

    assert_includes captured_output.string, expected_curl
  end

  def test_body_as_string
    body = '{"raw":"json"}'
    expected_curl = "-d '#{body}'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.post('/', body: body)

    assert_includes captured_output.string, expected_curl
  end

  def test_headers_case_insensitivity
    headers = { 'content-type' => 'application/json', 'ACCEPT' => 'application/json' }
    expected_curl_content_type = "-H 'content-type: application/json'"
    expected_curl_accept = "-H 'ACCEPT: application/json'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/', headers: headers)

    assert_includes captured_output.string, expected_curl_content_type
    assert_includes captured_output.string, expected_curl_accept
  end

  def test_handles_nil_options
    expected_curl = "curl -X GET 'http://example.com/'"

    captured_output = StringIO.new
    HttpPartyCurl.configuration.logger = Logger.new(captured_output)

    @client_class.get('/', nil)

    assert_includes captured_output.string, expected_curl
  end
end
