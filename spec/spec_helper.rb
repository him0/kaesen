$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'kaesen'
require 'dotenv'

Dotenv.load '.env'

RSpec.configure do |config|
  config.mock_framework = :rspec
end