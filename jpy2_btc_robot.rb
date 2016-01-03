# -*- coding: utf-8 -*-

require './market.rb'
require './my_kraken.rb'
require './coincheck.rb'
require './my_zaif.rb'
require './bit_flyer_lightning'
require 'logger'

class Jpy2BtcRobot
  def initialize
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

  def update
    out = ""

    threads = []
    @markets.each {|m|
      threads.push(Thread.new {
        m.update()
      })
    }
    threads.each {|t|
      out += t.join.value
    }

    out += separate
    out += Time.now.to_s + "\n"
    out += separate
    out
  end

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

    out += separate
    out
  end

  def get_property
    out = ""
    @property = 0
    @markets.each{|m|
      @property += m.total_prperty
      out += sprintf("%-10s: ", m.name)
      out += sprintf("%-7.4f ", m.left_jpy)
      out += sprintf("%-7.4f ", m.left_btc)
      out += sprintf("%-7.4f\n", m.total_prperty)

    }
    out += separate
    out += sprintf("Total" + " " * 5 + ": " + "%7.4f\n"%(@property))
    out += separate
    out
  end

  def log_property
    get_property
    @log.info(sprintf("Total Property: " + "%7.4f"%(@property)))
  end

  def trade_rule_1
  end

  def separate
    sprintf("-" * 40 + "\n")
  end

end
