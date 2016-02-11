require 'bigdecimal'

# A module of the united wrapper for exchanging Japanese yen and Bitcoin and
# collecting market information of any exchange markets that provide ordinary
# customers with API access.
module Bot

    # @abstract
    # Abstruct Class of Exchange Markets.
    class Market

      def initialize
        @name = raise NotImplementedError.new() # [String] The name of Exchange Market
        @ticker = raise NotImplementedError.new() # [hash] Ticker
                                             # ask: [BigDecimal] 最良売気配値
                                             #   bid: [BigDecimal] 最良買気配置
                                             #   last: [BigDecimal]
                                             #   high: [BigDecimal] 高値
                                             #   low: [BigDecimal] 安値
                                             #   timestamp: [int] タイムスタンプ
                                             #   volume: [BigDecimal] 取引量
        @asset = raise NotImplementedError.new()  # [hash]
                                             # jpy: [BigDecimal] 円
                                             #   btc: [BigDecimal] BTC, Bitcoin
        @asset_avail = raise NotImplementedError.new() # [hash]
        @depth = raise NotImplementedError.new()  # [hash] Order book
                                             #   asks: [array]
                                             #     price: [BigDecimal]
                                             #     amount: [BigDecimal]
                                             #   bids: [array]
                                             #   timestamp: [int]
        @api_key    = raise NotImplementedError.new() # [String]
        @api_secret = raise NotImplementedError.new() # [String]
      end

      # Update market information.
      # @abstract
      # @return ?
      def update
        raise NotImplemented.new()
      end

      # Get total assets in JPY.
      # @return [float] property
      def asset_in_jpy
        (@asset[:jpy] + @asset[:btc] * @ticker[:last]).to_f
      end

      # Buy the amount of Bitcoin at the rate.
      # 指数注文 買い.
      # @abstract
      # @param [BigDecimal] rate
      # @param [BigDecimal] amount
      # @return [hash] history_order_hash
      def buy(rate, amount=BigDecimal("0.0"))
        raise NotImplemented.new()
      end

      # Sell the amount of Bitcoin at the rate.
      # 指数注文 売り.
      # @abstract
      # @param [BigDecimal] rate
      # @param [BigDecimal] amount
      # @return [hash] history_order_hash
      def sell(rate, amount=BigDecimal("0.0"))
        raise NotImplemented.new()
      end

      # Check the API key and API secret key.
      def have_key?
        raise "Your #{@name} API key is not set"    if @api_key.nil?
        raise "Your #{@name} API secret is not set" if @api_secret.nil?
      end

      attr_reader :ticker
      attr_reader :asset
      attr_reader :asset_avail
      attr_reader :depth

      private

      class ConnectionFailedException < StandardError; end
      class APIErrorException < StandardError; end
      class JSONException < StandardError; end

    end
end
