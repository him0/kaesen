# coding: utf-8
require 'bigdecimal'            # http://docs.ruby-lang.org/ja/2.2.0/class/BigDecimal.html
                                # バージョンによって最大有効桁数 n の取り扱いが変更される可能性があるのは要チェック。

# A module of the united wrapper for exchanging Japanese yen and Bitcoin and
# collecting market information of any exchange markets that provide ordinary
# customers with API access.
module Bot

    # Exchange markets.
    # @abstract
    class Market

      def initialize
        @name = nil         # [String] name of exchange market
        @api_key    = nil   # [String]
        @api_secret = nil   # [String]
        @url_public  = nil  # [String]
        @url_private = nil  # [String]
      end

      #############################################################
      # API for public information
      #############################################################

      # Get ticker information.
      # @abstract
      # @return [hash] ticker       
      #   ask: [N] 最良売気配値
      #   bid: [N] 最良買気配値
      #   last: [N] 最近値(?用語要チェック), last price
      #   high: [N] 高値    
      #   low: [N] 安値     
      #   timestamp: [int] タイムスタンプ(提供していない取引所もある)
      #   ltimestamp: [int] ローカルタイムスタンプ
      #   volume: [N] 取引量
      def ticker
        raise NotImplemented.new()
      end

      # Get order book.
      # @abstract
      # @return [hash] array of market depth
      def depth
        raise NotImplemented.new()
      end

      #############################################################
      # API for private user data and trading
      #############################################################

      # Get account balance.
      # @abstract
      # @return [hash] account_balance_hash
      #   jpy: [hash]
      #      amount: [N] 総日本円
      #      available: [N] 取引可能な日本円
      #   btc [hash]
      #      amount: [N] 総BTC
      #      available: [N] 取引可能なBTC
      def balance
        raise NotImplemented.new()
      end

      # Buy the amount of Bitcoin at the rate.
      # 指数注文 買い.
      # @abstract
      # @param [N] rate
      # @param [N] amount
      # @return [hash] history_order_hash
      def buy(rate, amount=N.new("0.0"))
        raise NotImplemented.new()
      end

      # Sell the amount of Bitcoin at the rate.
      # 指数注文 売り.
      # @abstract
      # @param [N] rate
      # @param [N] amount
      # @return [hash] history_order_hash
      def sell(rate, amount=N.new("0.0"))
        raise NotImplemented.new()
      end

      private

      # Check the API key and API secret key.
      def have_key?
        raise "Your #{@name} API key is not set"    if @api_key.nil?
        raise "Your #{@name} API secret is not set" if @api_secret.nil?
      end

      class ConnectionFailedException < StandardError; end
      class APIErrorException < StandardError; end
      class JSONException < StandardError; end

    end

    class Algorithm

      def initialize
        # nil をエクセプションに変えると super で呼び出したときエラーになる
        @ticker = nil       # [hash]
                            #   [market name]:
        @balance = nil      # [hash]
                            #   [market name]:
                            #     jpy: [N] JPY, 円
                            #     btc: [N] BTC, Bitcoin
        @depth = nil        # [hash] Order book
                            #   [market name]:
                            #     asks: [array]
                            #       price: [N]
                            #       amount: [N]
                            #     bids: [array]
                            #     timestamp: [int]
                            #     timestampl: [int]
      end

      # Update market information.
      # @param [Market]
      # @return [hash]
      def update_ticker(market)
        @ticker[market] = market.ticker
      end

      # Update asset information.
      # @param [Market]
      # @return [hash]
      def update_asset(market)
        @asset[market] = market.asset
      end

      # Get total assets in JPY.
      # @param [Market]
      # @return [float] property
      def asset_in_jpy(market)
        (@asset[market]["jpy"] + @asset[market]["btc"] * @ticker[market]["last"]).to_f
      end

      attr_reader :ticker
      attr_reader :asset
      attr_reader :asset_avail
      attr_reader :depth

    end

    class N < BigDecimal

      # @param [String], [Bignum], [Float], [Rational], or [BigDecimal]
      # @return [N]
      def initialize(s,n = 0)
        super(s,n) # 「n が 0 または省略されたときは、n の値は s の有効桁数とみなされます。」
      end

      # 売買する人にとって可読性が高い表現にする
      def inspect
        self.to_s("F")
      end
    end
end
