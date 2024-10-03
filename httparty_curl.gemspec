# httparty_curl.gemspec

Gem::Specification.new do |spec|
  spec.name          = "httparty_curl"
  spec.version       = "0.1.0"
  spec.authors       = ["TheScubaGeek"]

  spec.summary       = "A gem to log HTTParty requests as cURL commands."
  spec.description   = "HTTPartyCurl adds cURL logging capabilities to HTTParty requests for debugging purposes."
  spec.homepage      = "https://github.com/thescubageek/httparty_curl"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 3.0.0'

  spec.files         = Dir["lib/**/*", "test/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.22"
  spec.add_dependency "minitest", "~> 5.25"
  spec.add_dependency "webmock", "~> 3.23"
end
