module Kaesen
  class Client
    attr_reader :ticker
    attr_reader :balance
    attr_reader :depth

    def initialize
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
    def update_ticker(market)
      @ticker[market.name] = market.ticker
    end

    # Update market information.
    # @param [Market]
    # @return [hash]
    def update_depth(market)
      @ticker[market.name] = market.depth
    end

    # Update asset information.
    # @param [Market]
    # @return [hash]
    def balance(market)
      @asset[market.name] = market.balance
    end

    # Get total assets in JPY.
    # @param [Market]
    # @return [float] property
    def asset_in_jpy(market)
      (@asset[market.name]["jpy"] + @asset[market.name]["btc"] * @ticker[market.name]["last"]).to_f
    end
  end
end
