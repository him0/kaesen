require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'

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
    #   ask: [N] 最良売気配値
    #   bid: [N] 最良買気配値
    #   last: [N] 最近値(?用語要チェック), last price
    #   high: [N] 高値
    #   low: [N] 安値
    #   volume: [N] 取引量
    #   ltimestamp: [int] ローカルタイムスタンプ
    #   vwap: [N] 過去24時間の加重平均
    def ticker
      h = get_ssl(@url_public + "/ticker/btc_jpy")
      {
        "ask"        => N.new(h["ask"]),
        "bid"        => N.new(h["bid"]),
        "last"       => N.new(h["last"]),
        "high"       => N.new(h["high"]),
        "low"        => N.new(h["low"]),
        "volume"     => N.new(h["volume"].to_s),
        "ltimestamp" => Time.now.to_i,
        "vwap"       => N.new(h["vwap"].to_s)
      }
    end

    # Get order book.
    # @abstract
    # @return [hash] array of market depth
    #   asks: [Array] 売りオーダー
    #      price : [N]
    #      size : [N]
    #   bids: [Array] 買いオーダー
    #      price : [N]
    #      size : [N]
    #   ltimestamp: [int] ローカルタイムスタンプ
    def depth
      h = get_ssl(@url_public + "/depth/btc_jpy")
      {
        "asks"       => h["asks"].map{|a,b| [N.new(a), N.new(b.to_s)]}, # to_s でないと誤差が生じる
        "bids"       => h["bids"].map{|a,b| [N.new(a), N.new(b.to_s)]}, # to_s でないと誤差が生じる
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
    #      amount: [N] 総日本円
    #      available: [N] 取引可能な日本円
    #   btc [hash]
    #      amount: [N] 総BTC
    #      available: [N] 取引可能なBTC
    #   ltimestamp: [int] ローカルタイムスタンプ
    def balance
      have_key?
      address = @url_private
      body = { "method" => "get_info" }
      h = post_ssl(address, body)
      {
        "jpy"        => {
          "amount"    => N.new(h["deposit"]["jpy"].to_s),
          "available" => N.new(h["funds"]["jpy"].to_s),
        },
        "btc"        => {
          "amount"    => N.new(h["deposit"]["btc"].to_s),
          "available" => N.new(h["funds"]["btc"].to_s),
        },
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Bought the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # Abstract Method.
    # @param [N] rate
    # @param [N] amount
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [int] order id at the market
    #   rate: [N]
    #   amount: [N]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def buy(rate, amount=N.new(0))
      have_key?
      address = @url_private
      body = {
        "mathod"        => "trade",
        "currency_pair" => "btc_jpy",
        "action"        => "bid",
        "price"         => rate.to_i,
        "amount"        => amount.to_f.round(4)
      }
      h = post_ssl(address, body)
      result = h["success"].to_i == 1 ? "true" : "false"
      {
        "success"    => result,
        "id"         => h["return"]["order_id"],
        "rate"       => N.new(rate),
        "amount"     => N.new(amount.to_s),
        "order_type" => "sell",
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Sell the amount of Bitcoin at the rate.
    # 指数注文 売り.
    # Abstract Method.
    # @param [int] rate
    # @param [float] amount
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [int] order id at the market
    #   rate: [N]
    #   amount: [N]
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def sell(rate, amount=N.new(0))
      have_key?
      address = @url_private
      body = {
        "mathod"        => "trade",
        "currency_pair" => "btc_jpy",
        "action" => "ask",
        "price" => rate.to_i,
        "amount" => amount.to_f.round(4),
      }
      h = post_ssl(address, body)
      result = h["success"].to_i == 1 ? "true" : "false"
      {
        "success"    => result,
        "id"         => h["return"]["order_id"],
        "rate"       => N.new(rate),
        "amount"     => N.new(amount.to_s),
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
      next_nonce = (Time.now.to_i) * 100 % 1_000_000_000

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
              return json["return"]
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
