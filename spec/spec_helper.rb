$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'bundler/setup'
require 'kaesen'
require 'dotenv'

Dotenv.load '.env'

RSpec.configure do |config|
  config.mock_framework = :rspec
end

def test_ticker(m_ticker)
  ticker = m_ticker
  print ticker

  expect(ticker.class).to eq Hash
  expect(ticker["ask"].class).to eq BigDecimal
  expect(ticker["bid"].class).to eq BigDecimal
  expect(ticker["last"].class).to eq BigDecimal
  expect(ticker["high"]).to eq nil
  expect(ticker["low"]).to eq nil
  expect(ticker["volume"].class).to eq BigDecimal
  expect(ticker["ltimestamp"].class).to eq Fixnum
  expect(ticker["timestamp"].class).to eq Fixnum
end

def test_depth(m_depth)
  depth = m_depth
  print depth

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

def test_balance(m_balance)
  balance = m_balance
  print balance

  expect(balance.class).to eq Hash

  expect(balance["jpy"].class).to eq Hash
  expect(balance["btc"].class).to eq Hash
  expect(balance["ltimestamp"].class).to eq Fixnum

  expect(balance["jpy"]["amount"].class).to eq BigDecimal
  expect(balance["jpy"]["available"].class).to eq BigDecimal

  expect(balance["btc"]["amount"].class).to eq BigDecimal
  expect(balance["btc"]["available"].class).to eq BigDecimal
end
