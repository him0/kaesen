require 'test-unit'
require_relative './bitflyer.rb'
require 'pp'
require 'bigdecimal'            # http://docs.ruby-lang.org/ja/2.2.0/class/BigDecimal.html

class Bitflyer_Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @market = Bot::Bitflyer.new
  end

  def teardown
    # Do nothing
  end

  def test_ticker
    t = @market.ticker
    pp t

    assert(t.is_a?(Hash))

    assert(t["ask"].is_a?(Bot::N))
    assert(t["bid"].is_a?(Bot::N))
    assert(t["last"].is_a?(Bot::N))
    assert(t["high"].nil?)
    assert(t["low"].nil?)
    assert(t["volume"].is_a?(Bot::N))
    assert(t["ltimestamp"].is_a?(Integer))
    assert(t["timestamp"].is_a?(Integer))
  end

  def test_depth
    d = @market.depth
    pp d

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

  def test_balance
    a = @market.balance
    pp a

    assert(a.is_a?(Hash))
    assert(a["jpy"].is_a?(Hash))
    assert(a["btc"].is_a?(Hash))
    assert(a["jpy"]["amount"].is_a?(Bot::N))
    assert(a["jpy"]["available"].is_a?(Bot::N))
    assert(a["btc"]["amount"].is_a?(Bot::N))
    assert(a["btc"]["available"].is_a?(Bot::N))
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

end
