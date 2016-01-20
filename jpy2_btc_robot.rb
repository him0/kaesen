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
    @log.info("Start!")
    log_property
  end

  # Update markets Properties.
  # @return [String] out
  def update
    out = ""

    out += Time.now.to_s + "\n"
    out += separator
    @markets.map{|m|
        Thread.new{
          m.update
          out += m.name + " is updated.\n"
        }
    }.each(&:join)
    out += separator

    @markets.each{|m|
      out += sprintf("%-10s\n", m.name)
      out += sprintf("ask: %7.4f\n", m.ask)
      out += sprintf("bid: %7.4f\n", m.bid)
    }
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

  def logging_error(ex)
    @log.error(ex)
  end

  # sprintf separater
  def separator
    sprintf("-" * 40 + "\n")
  end

end

require './trade_rules.rb'

begin
  m = Jpy2BtcRobot.new()
  while true
    print(m.update)
    print(m.get_property)
    print(m.get_gap)
    print(m.trade_rule_1)
    print(m.trade_rule_2)
  end
rescue => ex
  m.logging_error(ex)
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
