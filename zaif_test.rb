require 'test-unit'
require_relative './zaif.rb'
require 'pp'
require 'bigdecimal'            # http://docs.ruby-lang.org/ja/2.2.0/class/BigDecimal.html

class Zaif_Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @market = Bot::Zaif.new
  end

  def teardown
    # Do nothing
  end

  def test_ticker
    t = @market.ticker
    pp t

    assert(t["bid"].is_a?(Bot::N))
    assert(t["ask"].is_a?(Bot::N))
    assert(t["low"].is_a?(Bot::N))
    assert(t["high"].is_a?(Bot::N))
    assert(t["last"].is_a?(Bot::N))
    assert(t["volume"].is_a?(Bot::N))
    assert(t["timestamp"].nil?)
    assert(t["ltimestamp"].is_a?(Integer))
    assert(t["vwap"].is_a?(Bot::N))
  end

  def test_depth
    d = @market.depth
    p d

    assert(d["asks"].is_a?(Array))
    assert(d["bids"].is_a?(Array))
    assert(d["ltimestamp"].is_a?(Integer))
  end

  def test_update
    t1 = @market.ticker
    pp t1
    sleep 2
    t2 = @market.ticker
    pp t2

    assert(t1["ltimestamp"] != t2["ltimestamp"])
  end

  def test_buy
    rate = Bot::N.new(30000)
    amount = Bot::N.new("0.012")
    # pp @market.buy(rate, amount)
  end

  def test_sell
    rate = Bot::N.new(70000)
    amount = Bot::N.new("0.012")
    # pp @market.sell(rate, amount)
  end


  def test_balance
    a = @market.balance
    pp a

    assert(a["funds"].is_a?(Hash))
  end

end
