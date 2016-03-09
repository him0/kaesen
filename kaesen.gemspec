# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kaesen/version'

Gem::Specification.new do |spec|
  spec.name          = "kaesen"
  spec.version       = Kaesen::VERSION
  spec.authors       = ["him0"]
  spec.email         = ["nakashimaorz@gmail.com"]

  spec.summary       = %q{A module of the united wrapper for exchanging Japanese yen and Bitcoin and collecting market information of any exchange markets that provide ordinary customers with API access.}
  spec.description   = %q{This is a module that exchanging Japanese yen and Bitcoin and collecting market information.}
  spec.homepage      = "http://github.com/him0/kaesen"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "dotenv"
end
