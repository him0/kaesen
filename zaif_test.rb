require 'test-unit'
require_relative './zaif.rb'
require 'pp'
require 'bigdecimal'

class Zaif_Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @zaif = Bot::Zaif.new
  end

  def teardown
    # Do nothing
  end

  def test_ticker
    ticker = @zaif.get_ticker

    pp ticker

    assert(ticker["bid"].is_a?(BigDecimal))
    assert(ticker["ask"].is_a?(BigDecimal))
    assert(ticker["low"].is_a?(BigDecimal))
    assert(ticker["high"].is_a?(BigDecimal))
    assert(ticker["last"].is_a?(BigDecimal))
    assert(ticker["volume"].is_a?(BigDecimal))
    assert(ticker["timestamp"].is_a?(Integer))
    assert(ticker["vwap"].is_a?(BigDecimal))
  end

  def test_update
    @zaif.update
    t1 = @zaif.ticker
    sleep 2
    @zaif.update
    t2 = @zaif.ticker

    assert(t1["timestamp"] != t2["timestamp"])
  end

  def test_buy
    rate = BigDecimal(30000)
    amount = BigDecimal("0.012")
#    pp @zaif.buy(rate, amount)
  end

  def test_sell
    rate = BigDecimal(50000)
    amount = BigDecimal("0.012")
    pp @zaif.sell(rate, amount)
  end
end