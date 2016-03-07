module Kaesen
  class Client
    attr_accessor :markets
    attr_reader :ticker
    attr_reader :balance
    attr_reader :depth

    def initialize
      @markets = []   # [Array]
                      #   [Market] instance of markets
      @ticker = {}    # [hash]
                      #   [market name]:
      @depth = {}     # [hash] Order book
                      #   [market name]:
                      #     asks: [array]
                      #       price: [BigDecimal]
                      #       amount: [BigDecimal]
                      #     bids: [array]
                      #     timestamp: [int]
                      #     timestampl: [int]
      @balance = {}   # [hash]
                      #   [market name]:
                      #     jpy: [BigDecimal] JPY, 円
                      #     btc: [BigDecimal] BTC, Bitcoin
    end

    # Update market information.
    # @param [Market]
    # @return [hash]
    def update_ticker()
      @markets.each{|m|
        @ticker[m.name] = m.ticker
      }
    end

    # Update market information.
    # @param [Market]
    # @return [hash]
    def update_depth()
      @markets.each{|m|
        @depth[m.name] = m.depth
      }
    end

    # Update asset information.
    # @param [Market]
    # @return [hash]
    def update_balance()
      @markets.each{|m|
        @balance[m.name] = m.balance
      }
    end
  end
end
