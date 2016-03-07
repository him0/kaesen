$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'kaesen'

RSpec.configure do |config|
  config.mock_framework = :rspec
end