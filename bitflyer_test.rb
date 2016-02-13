require 'test-unit'
require_relative './bitflyer.rb'
require 'pp'
require 'bigdecimal'            # http://docs.ruby-lang.org/ja/2.2.0/class/BigDecimal.html

class Bitflyer_Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @marcket = Bot::Bitflyer.new
  end

  def teardown
    # Do nothing
  end

  def test_ticker
    t = @marcket.ticker
    pp t

    assert(t["bid"].is_a?(Bot::N))
    assert(t["ask"].is_a?(Bot::N))
    assert(t["low"].nil?)
    assert(t["high"].nil?)
    assert(t["last"].is_a?(Bot::N))
    assert(t["volume"].is_a?(Bot::N))
    assert(t["timestamp"].is_a?(Integer))
    assert(t["ltimestamp"].is_a?(Integer))
    assert(t["vwap"].nil?)
  end

end
