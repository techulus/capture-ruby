# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "capture_page"
  spec.version = "1.2.0"
  spec.authors = ["Capture Team"]
  spec.email = ["support@capture.page"]

  spec.summary = "Ruby SDK for Capture - Screenshot and content extraction API"
  spec.description = "Official Ruby SDK for Capture (capture.page). Capture screenshots, generate PDFs, extract content and metadata from web pages."
  spec.homepage = "https://capture.page"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/techulus/capture-ruby"
  spec.metadata["documentation_uri"] = "https://docs.capture.page"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
