require 'test-unit'
require_relative './zaif.rb'
require 'pp'
require 'bigdecimal'            # http://docs.ruby-lang.org/ja/2.2.0/class/BigDecimal.html

class Zaif_Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    sleep(1.1)
    @market = Bot::Zaif.new
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
    assert(t["high"].is_a?(Bot::N))
    assert(t["low"].is_a?(Bot::N))
    assert(t["volume"].is_a?(Bot::N))
    assert(t["ltimestamp"].is_a?(Integer))
    assert(t["vwap"].is_a?(Bot::N))
  end

  def test_depth
    d = @market.depth
    pp d

    assert(d["asks"].is_a?(Array))
    assert(d["bids"].is_a?(Array))
    assert(d["ltimestamp"].is_a?(Integer))

    assert(d["asks"][0].is_a?(Array))

    assert(d["asks"][0][0].is_a?(Bot::N))
    assert(d["asks"][0][1].is_a?(Bot::N))

    assert(d["bids"][0].is_a?(Array))

    assert(d["bids"][0][0].is_a?(Bot::N))
    assert(d["bids"][0][1].is_a?(Bot::N))
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
    amount = Bot::N.new("0.010")
    b = @market.buy(rate, amount)

    assert(b.is_a?(Hash))

    assert(b["success"].is_a?(String))
    assert(b["id"].is_a?(Integer))
    assert(b["rate"].is_a?(Bot::N))
    assert(b["amount"].is_a?(Bot::N))
    assert(b["order_type"].is_a?(String))
    assert(b["ltimestamp"].is_a?(Integer))
  end

  def test_sell
    rate = Bot::N.new(70000)
    amount = Bot::N.new("0.010")
    s = @market.sell(rate, amount)

    assert(s.is_a?(Hash))

    assert(s["success"].is_a?(String))
    assert(s["id"].is_a?(Integer))
    assert(s["rate"].is_a?(Bot::N))
    assert(s["amount"].is_a?(Bot::N))
    assert(s["order_type"].is_a?(String))
    assert(s["ltimestamp"].is_a?(Integer))
  end

end
