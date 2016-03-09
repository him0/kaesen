require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'bigdecimal'

module Kaesen
  # Zaif Wrapper Class
  # https://corp.zaif.jp/api-docs/
  
  class Zaif < Market
    @@nonce = 0

    def initialize()
      super()
      @name        = "Zaif"
      @api_key     = ENV["ZAIF_KEY"]
      @api_secret  = ENV["ZAIF_SECRET"]
      @url_public  = "https://api.zaif.jp/api/1"
      @url_private = "https://api.zaif.jp/tapi"
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
    #   vwap: [BigDecimal] 過去24時間の加重平均
    def ticker
      h = get_ssl(@url_public + "/ticker/btc_jpy")
      {
        "ask"        => BigDecimal.new(h["ask"].to_s),
        "bid"        => BigDecimal.new(h["bid"].to_s),
        "last"       => BigDecimal.new(h["last"].to_s),
        "high"       => BigDecimal.new(h["high"].to_s),
        "low"        => BigDecimal.new(h["low"].to_s),
        "volume"     => BigDecimal.new(h["volume"].to_s),
        "ltimestamp" => Time.now.to_i,
        "vwap"       => BigDecimal.new(h["vwap"].to_s)
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
      h = get_ssl(@url_public + "/depth/btc_jpy")
      {
        "asks"       => h["asks"].map{|a,b| [BigDecimal.new(a.to_s), BigDecimal.new(b.to_s)]}, # to_s でないと誤差が生じる
        "bids"       => h["bids"].map{|a,b| [BigDecimal.new(a.to_s), BigDecimal.new(b.to_s)]}, # to_s でないと誤差が生じる
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
      address = @url_private
      body = { "method" => "get_info" }
      h = post_ssl(address, body)
      {
        "jpy"        => {
          "amount"    => BigDecimal.new(h["return"]["deposit"]["jpy"].to_s),
          "available" => BigDecimal.new(h["return"]["funds"]["jpy"].to_s),
        },
        "btc"        => {
          "amount"    => BigDecimal.new(h["return"]["deposit"]["btc"].to_s),
          "available" => BigDecimal.new(h["return"]["funds"]["btc"].to_s),
        },
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Bought the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # Abstract Method.
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [String] order id at the market
    #   rate: [BigDecimal] rate should be 5 multiples
    #   amount: [BigDecimal] minimal amount is 0.0001 BTC
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def buy(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private
      rate = (rate.to_i / 5) * 5
      body = {
        "method"        => "trade",
        "currency_pair" => "btc_jpy",
        "action"        => "bid",
        "price"         => rate,
        "amount"        => amount.to_f.round(4)
      }
      h = post_ssl(address, body)
      result = h["success"].to_i == 1 ? "true" : "false"
      {
        "success"    => result,
        "id"         => h["return"]["order_id"].to_s,
        "rate"       => BigDecimal.new(rate.to_s),
        "amount"     => BigDecimal.new(amount.to_s),
        "order_type" => "sell",
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
    #   rate: [BigDecimal] rate should be 5 multiples
    #   amount: [BigDecimal] minimal amount is 0.0001 BTC
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def sell(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private
      rate = (rate.to_i / 5) * 5
      body = {
        "method"        => "trade",
        "currency_pair" => "btc_jpy",
        "action" => "ask",
        "price" => rate,
        "amount" => amount.to_f.round(4),
      }
      h = post_ssl(address, body)
      result = h["success"].to_i == 1 ? "true" : "false"
      {
        "success"    => result,
        "id"         => h["return"]["order_id"].to_s,
        "rate"       => BigDecimal.new(rate.to_s),
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
      next_nonce = Time.now.to_i

      if next_nonce <= pre_nonce
        @@nonce = pre_nonce + 1
      else
        @@nonce = next_nonce
      end

      return @@nonce
    end

    def get_sign(req)
      secret = @api_secret
      text = req.body

      OpenSSL::HMAC::hexdigest(OpenSSL::Digest.new('sha512'), secret, text)
    end

    # Connect to address via https, and return json response.
    def post_ssl(address, data={})
      uri = URI.parse(address)
      data["nonce"] = get_nonce

      begin
        req = Net::HTTP::Post.new(uri)
        req.set_form_data(data)
        req["Key"] = @api_key
        req["Sign"] = get_sign(req)

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
