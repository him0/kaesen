# -*- coding: utf-8 -*-

require './market.rb'
require './my_kraken.rb'
require './coincheck.rb'
require './my_zaif.rb'
require './bit_flyer_lightning'
require 'logger'

# Main Class
class Jpy2BtcRobot

  def initialize()
    @log = Logger.new('./log/'+(Time.now().strftime("%Y-%m-%d"))+".log")
    @markets = []
    @markets.push(Coincheck.new())
    @markets.push(MyZaif.new())
    @markets.push(BitFlyerLightning.new())
    @min_ask_market = @markets[0] # Bitcoinの買値が一番安い
    @max_bid_market = @markets[0] # Bitcoinの売値が一番高い
    @gap = 0
    @gap_rate = 0

    @log.info("Start!")
    log_property
  end

  # Update markets Properties.
  # @return [String] out
  def update
    out = ""

    threads = []
    @markets.each {|m|
      threads.push(Thread.new {
        m.update()
        out += m.name + " is updated.\n"
      })
    }
    threads.each {|t|
      out += t.join.value
    }

    out += separator
    out += Time.now.to_s + "\n"
    out += separator
    out
  end

  # Get the gap of market prices.
  # @return [String] out
  def get_gap
    out = ""

    @markets.each{|m|
      @min_ask_market = m.ask < @min_ask_market.ask ? m : @min_ask_market
      @max_bid_market = @max_bid_market.bid < m.bid ? m : @max_bid_market
      out += sprintf("%-10s\n", m.name)
      out += sprintf("ask: %7.4f\n", m.ask)
      out += sprintf("bid: %7.4f\n", m.bid)
    }

    min_ask = @min_ask_market.ask
    min_ask_name = @min_ask_market.name
    out += sprintf("Minimal Ask: %7.4f (%s)\n", min_ask, min_ask_name)

    max_bid = @max_bid_market.bid
    max_bid_name = @max_bid_market.name
    out += sprintf("Maximam Bid: %7.4f (%s)\n", max_bid, max_bid_name)

    @gap = max_bid - min_ask
    @gap_rate = (max_bid / min_ask) * 100
    out += sprintf("This Gap is %7.4f(%3.2f)\n", @gap, @gap_rate)

    out += separator
    out
  end

  # Get the total of properties.
  # @return [String] out
  def get_property
    out = ""
    @property = 0
    @markets.each{|m|
      @property += m.total_prperty
      out += sprintf("%-10s: ", m.name)
      out += sprintf("%-7.4f ", m.jpy)
      out += sprintf("%-7.4f ", m.btc)
      out += sprintf("%-7.4f\n", m.total_prperty)

    }
    out += separator
    out += sprintf("Total" + " " * 5 + ": " + "%7.4f\n"%(@property))
    out += separator
    out
  end

  # Logging the total of properties.
  def log_property
    get_property
    @log.info(sprintf("Total Property: " + "%7.4f"%(@property)))
  end

  # Trade with rule.
  def trade_rule_1
    out = ""
    # border = 100
    rate_border = 100.20
    amount = 0.1
    jpy_limit = 7000
    btc_limit = 0.1
    min_ask = @min_ask_market.raw_ask
    min_ask_name = @min_ask_market.name
    max_bid = @max_bid_market.raw_bid
    max_bid_name = @max_bid_market.name
    if (@gap_rate > rate_border &&
      @min_ask_market.jpy >= jpy_limit &&
      @max_bid_market.btc >= btc_limit &&
      @min_ask_market != @max_bid_market)
      @min_ask_market.buy(min_ask, amount)
      m = sprintf("Buy %f bitcoin(%.0f) @%s", amount, min_ask, min_ask_name)
      @log.info(m)
      out += m + "\n"

      @max_bid_market.sell(max_bid, amount)
      m = sprintf("Sell %f bitcoin(%.0f) @%s", amount, max_bid, max_bid_name)
      @log.info(m)
      out += m + "\n"

      earn = @gap * amount
      m = sprintf("Earn %f yen!", earn)
      @log.info(m)
      out += m + "\n"
      log_property
      out
    end
  end

  # sprintf separater
  def separator
    sprintf("-" * 40 + "\n")
  end

end



begin
  m = Jpy2BtcRobot.new()
  while true
    print(m.update)
    print(m.get_property)
    print(m.get_gap)
    print(m.trade_rule_1)
  end
rescue
    retry
ensure
  m.log_property
end

# c = Coincheck.new
# print(c.ask.to_s + "\n" + c.bid.to_s + "\n")
# print(c.raw_ask.to_s + "\n" + c.raw_bid.to_s + "\n")
# print(c.buy(51000, 0.01))
# print(c.sell(53000, 0.01))
# print(c.get_history(30178602))

# z = MyZaif.new
# print(z.ask.to_s + "\n" + z.bid.to_s + "\n")
# print(z.buy(51000, 0.01))
# print(z.sell(53000.1, 0.01))

# bl = BitFlyerLightning.new
# print(bl.ask.to_s + "\n" + bl.bid.to_s + "\n")
# print(bl.buy(51000, 0.01))
# print(bl.sell(51000, 0.01))
