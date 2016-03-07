require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'bigdecimal'

module Kaesen
  # Coincheck Wrapper Class
  # https://coincheck.jp/documents/exchange/api?locale=ja

  class Coincheck < Market
    @@nonce = 0

    def initialize()
      super()
      @name        = "Coincheck"
      @api_key     = ENV["COINCHECK_KEY"]
      @api_secret  = ENV["COINCHECK_SECRET"]
      @url_public  = "https://coincheck.jp"
      @url_private = @url_public
    end

    #############################################################
    # API for public information
    #############################################################

    # Get ticker information.
    # @return [hash] ticker
    #   ask: [BigDecimal] 最良売気配値
    #   bid: [BigDecimal] 最良買気配値
    #   last: [BigDecimal] 最近値(?用語要チェック), last price
    #   high: [BigDecimal] 高値
    #   low: [BigDecimal] 安値
    #   volume: [BigDecimal] 取引量
    #   ltimestamp: [int] ローカルタイムスタンプ
    #   timestamp: [int] タイムスタンプ
    def ticker
      h = get_ssl(@url_public + "/api/ticker")
      {
        "ask"        => BigDecimal.new(h["ask"].to_s),
        "bid"        => BigDecimal.new(h["bid"].to_s),
        "last"       => BigDecimal.new(h["last"].to_s),
        "high"       => BigDecimal.new(h["high"].to_s),
        "low"        => BigDecimal.new(h["low"].to_s),
        "volume"     => BigDecimal.new(h["volume"].to_s), # h["volume"] は String
        "ltimestamp" => Time.now.to_i,
        "timestamp"  => h["timestamp"],
      }
    end

    # Get order book.
    # @abstract
    # @return [hash] array of market depth
    #   asks: [Array] 売りオーダー
    #      price : [BigDecimal]
    #      size : [BigDecimal]
    #   bids: [Array] 買いオーダー
    #      price : [BigDecimal]
    #      size : [BigDecimal]
    #   ltimestamp: [int] ローカルタイムスタンプ
    def depth
      h = get_ssl(@url_public + "/api/order_books")
      {
        "asks"       => h["asks"].map{|a,b| [BigDecimal.new(a.to_s), BigDecimal.new(b.to_s)]},
        "bids"       => h["bids"].map{|a,b| [BigDecimal.new(a.to_s), BigDecimal.new(b.to_s)]},
        "ltimestamp" => Time.now.to_i,
      }
    end

    #############################################################
    # API for private user data and trading
    #############################################################

    # Get account balance.
    # @abstract
    # @return [hash] account_balance_hash
    #   jpy: [hash]
    #      amount: [BigDecimal] 総日本円
    #      available: [BigDecimal] 取引可能な日本円
    #   btc [hash]
    #      amount: [BigDecimal] 総BTC
    #      available: [BigDecimal] 取引可能なBTC
    #   ltimestamp: [int] ローカルタイムスタンプ
    def balance
      have_key?
      address = @url_private + "/api/accounts/balance"
      h = get_ssl_with_sign(address)
      {
        "jpy"        => {
          "amount"    => BigDecimal.new(h["jpy"].to_s) + BigDecimal.new(h["jpy_reserved"].to_s),
          "available" => BigDecimal.new(h["jpy"].to_s),
        },
        "btc"        => {
          "amount"    => BigDecimal.new(h["btc"].to_s) + BigDecimal.new(h["btc_reserved"].to_s),
          "available" => BigDecimal.new(h["btc"].to_s),
        },
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Buy the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # @abstract
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount # # minimal trade amount is 0.005 BTC
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [int] order id at the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    #   timestamp: [int] タイムスタンプ
    def buy(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private + "/api/exchange/orders"
      body = {
         "rate"       => rate.to_i,
         "amount"     => amount.to_f.round(4),
         "order_type" => "buy",
         "pair"       => "btc_jpy",
      }
      h = post_ssl_with_sign(address,body)
      {
        "success"    => h["success"].to_s,
        "id"         => h["id"],
        "rate"       => BigDecimal.new(h["rate"].to_s),
        "amount"     => BigDecimal.new(h["size"].to_s),
        "order_type" => h["order_type"],
        "ltimestamp" => Time.now.to_i,
        "timestamp"  => DateTime.parse(h["created_at"]).to_time.to_i,
      }
    end

    # Sell the amount of Bitcoin at the rate.
    # 指数注文 売り.
    # @abstract
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount # minimal trade amount is 0.005 BTC
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [int] order id at the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    #   timestamp: [int] タイムスタンプ
    def sell(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private + "/api/exchange/orders"
      body = {
        "rate"       => rate.to_i,
        "amount"     => amount.to_f.round(4),
        "order_type" => "sell",
        "pair"       => "btc_jpy",
      }
      h = post_ssl_with_sign(address,body)
      {
        "success"    => h["success"].to_s,
        "id"         => h["id"],
        "rate"       => BigDecimal.new(h["rate"].to_s),
        "amount"     => BigDecimal.new(h["size"].to_s),
        "order_type" => h["order_type"],
        "ltimestamp" => Time.now.to_i,
        "timestamp"  => DateTime.parse(h["created_at"]).to_time.to_i,
      }
    end

    private

    def initialize_https(uri)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 5
      https.read_timeout = 15
      https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      https.verify_depth = 5
      https
    end

    def get_nonce
      pre_nonce = @@nonce
      # 桁数揃えないとエラーになる
      next_nonce = (Time.now.to_i) * 100 % 10_000_000_000

      if next_nonce <= pre_nonce
        @@nonce = pre_nonce + 1
      else
        @@nonce = next_nonce
      end

      return @@nonce
    end

    def get_sign(address, nonce, body)
      secret = @api_secret
      text = nonce.to_s + address.to_s + body

      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, text)
    end

    # Connect to address via https, and return json response.
    def get_ssl(address)
      uri = URI.parse(address)
      begin
        https = initialize_https(uri)
        https.start {|w|
          response = w.get(uri.request_uri)
          case response
            when Net::HTTPSuccess
              json = JSON.parse(response.body)
              raise JSONException, response.body if json == nil
              return json
            else
              raise ConnectionFailedException, "Failed to connect to #{@name}."
          end
        }
      rescue
        raise
      end
    end

    def get_headers(address, nonce, body="")
      {
        "ACCESS-KEY"       => @api_key,
        "ACCESS-NONCE"     => nonce.to_s,
        "ACCESS-SIGNATURE" => get_sign(address, nonce, body.to_json),
        "Content-Type"     => "application/json",
      }
    end

    # Connect to address via https, and return json response.
    def get_ssl_with_sign(address,body="")
      uri = URI.parse(address)
      nonce = get_nonce
      headers = get_headers(address, nonce, body)

      begin
        req = Net::HTTP::Get.new(uri, headers)
        req.body = body.to_json

        https = initialize_https(uri)
        https.start {|w|
          response = w.request(req)
          case response
            when Net::HTTPSuccess
              json = JSON.parse(response.body)
              raise JSONException, response.body if json == nil
              return json
            else
              raise ConnectionFailedException, "Failed to connect to #{@name}: " + response.value
          end
        }
      rescue
        raise
      end
    end

    def post_ssl_with_sign(address, body="")
      uri = URI.parse(address)
      nonce = get_nonce
      headers = get_headers(address, nonce, body)

      begin
        req = Net::HTTP::Post.new(uri, headers)
        req.body = body.to_json

        https = initialize_https(uri)
        https.start {|w|
          response = w.request(req)
          case response
            when Net::HTTPSuccess
              json = JSON.parse(response.body)
              return json
            else
              raise ConnectionFailedException, "Failed to connect to #{@name}: " + response.value
          end
        }
      rescue
        raise
      end
    end
  end
end
