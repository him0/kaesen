require 'test-unit'
require_relative './lake.rb'
require 'pp'
require 'bigdecimal'            # http://docs.ruby-lang.org/ja/2.2.0/class/BigDecimal.html

class Lake_Test < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @market = Bot::Lake.new
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
    assert(t["vwap"].nil?)
  end

end
