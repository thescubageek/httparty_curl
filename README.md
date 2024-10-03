
# HTTPartyCurl::Logger

`HTTPartyCurl::Logger` is a module that extends HTTParty to log HTTP requests as cURL commands. This is useful for debugging and inspecting outgoing requests in a readable format, replicating them in a terminal if needed.

## Features

- Logs HTTP requests made using HTTParty as cURL commands.
- Supports common HTTP methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`.
- Automatically includes headers, query parameters, authentication, and proxy settings in the cURL command.
- Customizable logging configuration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'httparty_curl'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install httparty_curl
```

## Usage

To use `HTTPartyCurl::Logger`, simply include it in your class that uses HTTParty _after_ you include `Http:

```ruby
require 'httparty_curl/logger'

class MyApiClient
  include HTTParty
  include HTTPartyCurl::Logger

  base_uri 'https://api.example.com'

  def fetch_data
    self.class.get('/data', headers: { 'Authorization' => 'Bearer token' })
  end
end
```

Now, every request will be logged as a cURL command if logging is enabled.

### Enabling Logging

To enable logging, you need to configure the `HTTPartyCurl` logger and set `curl_logging_enabled` to `true`. You can customize the logger based on your logging setup.

```ruby
HTTPartyCurl.configure do |config|
  config.curl_logging_enabled = true
  config.logger = Logger.new(STDOUT) # or any other logger
end
```

## Example Output

When a request is made, the cURL command will be logged like this:

```bash
HTTParty cURL command:
curl -X GET 'https://api.example.com/data' \
  -H 'Authorization: Bearer token'
```

### Proxy Support

If you are using proxies, the proxy settings will also be included in the cURL command:

```bash
HTTParty cURL command:
curl -X GET 'https://api.example.com/data' \
  --proxy 'http://proxy_user:proxy_pass@proxy.example.com:8080' \
  -H 'Authorization: Bearer token'
```

### Authentication

Basic and Digest authentication methods are also supported and included in the cURL command:

```bash
curl -X GET 'https://api.example.com/data' \
  -u 'username:password'
```

## Environment-Based Logging

By default, `HTTPartyCurl` enables cURL logging in `development` and `test` environments when used within a Rails application. In other environments, logging is disabled by default.

### Rails Applications

No additional configuration is needed. Logging is automatically enabled in `development` and `test` environments.

### Non-Rails Applications

For non-Rails applications, you can manually set the environment or configure logging:

```ruby
# Set the environment (e.g., :development, :test, :production)
HTTPartyCurl.configuration.environment = :development

# Or manually enable logging
HTTPartyCurl.configuration.curl_logging_enabled = true
```

## Customization

### Supported HTTP Methods

By default, the following HTTP methods are overridden with logging:

- `GET`
- `POST`
- `PUT`
- `PATCH`
- `DELETE`

### Custom Headers, Body, and Query Parameters

The cURL command generation handles headers, query parameters, and request body data (including multipart forms and JSON payloads).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thescubageek/httparty_curl.

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
