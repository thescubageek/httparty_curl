# http_party_curl.gemspec

Gem::Specification.new do |spec|
  spec.name          = "http_party_curl"
  spec.version       = HttpPartyCurl::VERSION
  spec.authors       = ["TheScubaGeek"]

  spec.summary       = "A gem to log HTTParty requests as cURL commands."
  spec.description   = "HttpPartyCurl adds cURL logging capabilities to HTTParty requests for debugging purposes."
  spec.homepage      = "https://github.com/thescubageek/http_party_curl"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.5.0"

  spec.files         = Dir["lib/**/*.rb"] + ["README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty"
  spec.add_dependency "logger"

  # If you chose minitest as your test framework
  spec.add_development_dependency "minitest", "~> 5.0"
end
