require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'
require 'bigdecimal'

module Kaesen
  # BitFlyer Wrapper Class
  # https://coincheck.jp/documents/exchange/api?locale=ja
  ## API制限
  ## . Private API は 1 分間に約 200 回を上限とします。
  ## . IP アドレスごとに 1 分間に約 500 回を上限とします。
  
  class Bitflyer < Market
    @@nonce = 0

    def initialize()
      super()
      @name        = "BitFlyer"
      @api_key     = ENV["BITFLYER_KEY"]
      @api_secret  = ENV["BITFLYER_SECRET"]
      @url_public  = "https://api.bitflyer.jp/v1"
      @url_private = @url_public
      @product_code = "BTC_JPY"
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
      h = get_ssl(@url_public + "/getticker?product_code=#{@product_code}")
      {
        "ask"        => BigDecimal.new(h["best_ask"].to_s),
        "bid"        => BigDecimal.new(h["best_bid"].to_s),
        "last"       => BigDecimal.new(h["ltp"].to_s),
        # "high" is not supplied.
        # "low" is not supplied.
        "volume"     => BigDecimal.new(h["volume"].to_s),
        "ltimestamp" => Time.now.to_i,
        "timestamp"  => DateTime.parse(h["timestamp"]).to_time.to_i,
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
      h = get_ssl(@url_public + "/getboard?product_code=#{@product_code}")
      {
        "asks"       => h["asks"].map{|x| [BigDecimal.new(x["price"].to_s), BigDecimal.new(x["size"].to_s)]},
        "bids"       => h["bids"].map{|x| [BigDecimal.new(x["price"].to_s), BigDecimal.new(x["size"].to_s)]},
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
      h = get_ssl_with_sign(@url_private + "/me/getbalance")
      {
        "jpy"        => {
          "amount"    => BigDecimal.new(h[0]["amount"].to_s),
          "available" => BigDecimal.new(h[0]["available"].to_s),
        },
        "btc"        => {
          "amount"    => BigDecimal.new(h[1]["amount"].to_s),
          "available" => BigDecimal.new(h[1]["available"].to_s),
        },
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Get open orders.
    # @abstract
    # @return [Array] open_orders_array
    #   @return [hash] history_order_hash
    #     success: [bool]
    #     id: [String] order id in the market
    #     rate: [BigDecimal]
    #     amount: [BigDecimal]
    #     order_type: [String] "sell" or "buy"
    #     order_status: [String] "active", "completed" or "canceled"
    #   ltimestamp: [int] Local Timestamp
    def opens
      have_key?
      address = @url_private + "/me/getchildorders"
      query = {
        "child_order_state" => "ACTIVE",
      }
      address += "?" + query.to_a.map{|x|"#{x[0]}=#{x[1]}" }.join("&")
      body = {
        "product_code" => @product_code,
      }
      a = get_ssl_with_sign(address, body)
      a.map{|x|
        {
          "success"    => "true",
          "id"         => x["id"],
          "rate"       => BigDecimal.new(x["average_price"].to_s),
          "amount"     => BigDecimal.new(x["size"].to_s),
          "order_type" => x["side"].downcase,
        }
      }
    end

    # Buy the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # @abstract
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount minimal amount is 0.001 BTC
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [String] order id at the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def buy(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private + "/me/sendchildorder"
      body = {
        "product_code"     => @product_code,
        "child_order_type" => "LIMIT",
        "side"             => "BUY",
        "price"            => rate.to_i,
        "size"             => amount.to_f.round(4),
        "minute_to_expire" => 525600,
        "time_in_force"    => "GTC",
      }
      h = post_ssl_with_sign(address, body)
      {
        "success"    => "true",
        "id"         => h["child_order_acceptance_id"].to_s,
        "rate"       => BigDecimal.new(rate.to_s),
        "amount"     => BigDecimal.new(amount.to_s),
        "order_type" => "buy",
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Buy the amount of Bitcoin from the market.
    # 成行注文 買い.
    # @abstract
    # @param [BigDecimal] amount
    # @return [hash] history_order_hash
    #   success: [bool]
    #   id: [String] order id in the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] Local Timestamp
    def market_buy(amount=BigDecimal.new("0.0"))
      have_key?
      address = @url_private + "/me/sendchildorder"
      body = {
        "product_code"     => @product_code,
        "child_order_type" => "MARKET",
        "side"             => "BUY",
        "size"             => amount.to_f.round(4),
        "minute_to_expire" => 525600,
        "time_in_force"    => "GTC",
      }
      h = post_ssl_with_sign(address, body)
      {
        "success"    => "true",
        "id"         => h["child_order_acceptance_id"].to_s,
        # "rate" is not supplied.
        "amount"     => BigDecimal.new(amount.to_s),
        "order_type" => "buy",
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Sell the amount of Bitcoin at the rate.
    # 指数注文 売り.
    # Abstract Method.
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [String] order id at the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def sell(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private + "/me/sendchildorder"
      body = {
        "product_code"     => @product_code,
        "child_order_type" => "LIMIT",
        "side"             => "SELL",
        "price"            => rate.to_i,
        "size"             => amount.to_f.round(4),
        "minute_to_expire" => 525600,
        "time_in_force"    => "GTC",
      }
      h = post_ssl_with_sign(address, body)
      {
        "success"    => "true",
        "id"         => h["child_order_acceptance_id"].to_s,
        "rate"       => BigDecimal.new(rate.to_s),
        "amount"     => BigDecimal.new(amount.to_s),
        "order_type" => "sell",
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Sell the amount of Bitcoin to the market.
    # 成行注文 売り.
    # @abstract
    # @param [BigDecimal] amount
    # @return [hash] history_order_hash
    #   success: [bool]
    #   id: [String] order id in the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] Local Timestamp
    def market_sell(amount=BigDecimal.new("0.0"))
      have_key?
      address = @url_private + "/me/sendchildorder"
      body = {
        "product_code"     => @product_code,
        "child_order_type" => "MARKET",
        "side"             => "SELL",
        "size"             => amount.to_f.round(4),
        "minute_to_expire" => 525600,
        "time_in_force"    => "GTC",
      }
      h = post_ssl_with_sign(address, body)
      {
        "success"    => "true",
        "id"         => h["child_order_acceptance_id"].to_s,
        # "rate" is not supplied.
        "amount"     => BigDecimal.new(amount.to_s),
        "order_type" => "sell",
        "ltimestamp" => Time.now.to_i,
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

    def get_nonce
      pre_nonce = @@nonce
      next_nonce = (1000*Time.now.to_f).to_i

      if next_nonce <= pre_nonce
        @@nonce = pre_nonce + 1
      else
        @@nonce = next_nonce
      end

      return @@nonce
    end

    def get_sign(uri, method, nonce, body)
      secret = @api_secret
      text = nonce.to_s + method + uri.request_uri
      text += body.to_json if body != ""

      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, text)
    end

    def get_headers(uri, method, nonce, body="")
      {
        "ACCESS-KEY" => @api_key,
        "ACCESS-TIMESTAMP" => nonce.to_s,
        "ACCESS-SIGN" => get_sign(uri, method, nonce, body),
        "Content-Type" => "application/json",
      }
    end

    def get_ssl_with_sign(address, body="")
      uri = URI.parse(address)
      nonce = get_nonce
      headers = get_headers(uri, "GET", nonce, body)

      begin
        req = Net::HTTP::Get.new(uri, headers)
        req.body = body.to_json if body != ""

        https = https = initialize_https(uri)
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
      headers = get_headers(uri, "POST", nonce, body)

      begin
        req = Net::HTTP::Post.new(uri, headers)
        req.body = body.to_json if body != ""

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

  end
end
