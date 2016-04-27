$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'kaesen'
require 'dotenv'

Dotenv.load '.env'

RSpec.configure do |config|
  config.mock_framework = :rspec
end

def test_depth(depth)
  print unBigDecimal(depth)

  expect(depth.class).to eq Hash
  expect(depth["asks"].class).to eq Array
  expect(depth["asks"][0].class).to eq Array
  expect(depth["asks"][1].class).to eq Array

  expect(depth["asks"][0][0].class).to eq BigDecimal
  expect(depth["asks"][0][1].class).to eq BigDecimal

  expect(depth["asks"][1][0].class).to eq BigDecimal
  expect(depth["asks"][1][1].class).to eq BigDecimal

  expect(depth["bids"].class).to eq Array

  expect(depth["bids"][0].class).to eq Array
  expect(depth["bids"][1].class).to eq Array

  expect(depth["bids"][0][0].class).to eq BigDecimal
  expect(depth["bids"][0][1].class).to eq BigDecimal

  expect(depth["bids"][1][0].class).to eq BigDecimal
  expect(depth["bids"][1][1].class).to eq BigDecimal
end

def test_balance(balance)
  print unBigDecimal(balance)

  expect(balance.class).to eq Hash

  expect(balance["jpy"].class).to eq Hash
  expect(balance["btc"].class).to eq Hash
  expect(balance["ltimestamp"].class).to eq Fixnum

  expect(balance["jpy"]["amount"].class).to eq BigDecimal
  expect(balance["jpy"]["available"].class).to eq BigDecimal

  expect(balance["btc"]["amount"].class).to eq BigDecimal
  expect(balance["btc"]["available"].class).to eq BigDecimal
end

def test_opens(opens)
  print unBigDecimal(opens)

  expect(opens.class).to eq Array

  # expect(opens[0].class).to eq Hash
  #
  # expect(opens[0]["success"])
  # expect(opens[0]["id"])
  # expect(opens[0]["rate"])
  # expect(opens[0]["amount"])
  # expect(opens[0]["order_type"])
end

def test_oreder_result(result)
  print unBigDecimal(result)

  expect(result.class).to eq Hash

  expect(result["success"].class).to eq String
  expect(result["id"].class).to eq String
  expect(result["rate"].class).to eq BigDecimal
  expect(result["amount"].class).to eq BigDecimal
  expect(result["order_type"].class).to eq String
  expect(result["ltimestamp"].class).to eq Fixnum
end
