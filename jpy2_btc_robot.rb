# -*- coding: utf-8 -*-

require './market.rb'
require './my_kraken.rb'
require './coincheck.rb'
require './my_zaif.rb'
require './bit_flyer_lightning'
require 'logger'

class Jpy2BtcRobot
  def initialize
    @log = Logger.new('./log/'+(Time.now().to_i.to_s)+".log")
    @log.info("Start!")
    @markets = []
    @markets.push(Coincheck.new())
    @markets.push(MyZaif.new())
    @markets.push(BitFlyerLightning.new())
    @min_ask_market = @markets[0] # 買値が一番安い
    @max_bid_market = @markets[0] # 売値が一番高い
    @gap = 0
    @gap_rate = 0
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

    for m in @markets
      # out += sprintf("%-10s\n", m.name)
      # out += sprintf("ask: %7.4f\n", m.ask)
      # out += sprintf("bid: %7.4f\n", m.bid)
      @min_ask_market = m.ask < @min_ask_market.ask ? m : @min_ask_market
      @max_bid_market = @max_bid_market.bid < m.bid ? m : @min_ask_market
    end

    @min_ask = @min_ask_market.ask
    min_ask_name = @min_ask_market.name
    out += sprintf("Minimal Ask: %7.4f (%s)\n", @min_ask, min_ask_name)

    @max_bid = @max_bid_market.bid
    max_bid_name = @max_bid_market.name
    out += sprintf("Maximam Bid: %7.4f (%s)\n", @max_bid, max_bid_name)

    @gap = @max_bid - @min_ask
    @gap_rate = (@max_bid / @min_ask) * 100

    out += sprintf("This Gap is %7.4f(%3.2f)\n", @gap, @gap_rate)

    out += separate
    out
  end

  def get_property
    out = ""
    p = 0
    for m in @markets
      p += m.total_prperty
      out += sprintf("%-10s: ", m.name)
      out += sprintf("%7.4f ", m.left_jpy)
      out += sprintf("%7.4f ", m.left_btc)
      out += sprintf("%7.4f\n", m.total_prperty)
    end
    out += separate
    out += sprintf("Total" + " " * 5 + ": " + "%7.4f\n"%(p))
    out += separate
    out
  end

  def separate
    sprintf("-" * 40 + "\n")
  end

end
