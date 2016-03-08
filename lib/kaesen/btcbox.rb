require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'bigdecimal'

module Kaesen
  # BtcBox Wrapper Class
  # https://www.btcbox.co.jp/help/api.html

  class Btcbox < Market
    @@nonce = 0

    def initialize()
      super()
      @name        = "BtcBox"
      @api_key     = ENV["BTCBOX_KEY"]
      @api_secret  = ENV["BTCBOX_SECRET"]
      @url_public  = "https://www.btcbox.co.jp/api/v1"
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
    def ticker
      h = get_ssl(@url_public + "/ticker")
      {
        "ask"        => BigDecimal.new(h["sell"].to_s),
        "bid"        => BigDecimal.new(h["buy"].to_s),
        "last"       => BigDecimal.new(h["last"].to_s),
        "high"       => BigDecimal.new(h["high"].to_s),
        "low"        => BigDecimal.new(h["low"].to_s),
        "volume"     => BigDecimal.new(h["vol"].to_s),
        "ltimestamp" => Time.now.to_i,
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
      h = get_ssl(@url_public + "/depth")
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
      h = post_ssl(@url_private + "/balance/")
      {
        "jpy"        => {
          "amount"    => BigDecimal.new(h["jpy_balance"].to_s) + BigDecimal.new(h["jpy_lock"].to_s),
          "available" => BigDecimal.new(h["jpy_balance"].to_s),
        },
        "btc"        => {
          "amount"    => BigDecimal.new(h["btc_balance"].to_s) + BigDecimal.new(h["btc_lock"].to_s),
          "available" => BigDecimal.new(h["btc_balance"].to_s),
        },
        "ltimestamp" => Time.now.to_i,
      }
    end

    # Bought the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # Abstract Method.
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount # minimal trade amount is 0.01 BTC
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [String] order id at the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal] minimal amount is 0.01 BTC
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def buy(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private + "/trade_add/"
      params = {
        "amount" => amount.to_f.round(4),
        "price"  => rate.to_i,
        "type"   => "buy",
      }
      h = post_ssl(address, params)
      {
        "success"    => h["result"].to_s,
        "id"         => h["id"].to_s,
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
    # @param [BigDecimal] amount # minimal trade amount is 0.01 BTC
    # @return [hash] history_order_hash
    #   success: [String] "true" or "false"
    #   id: [String] order id at the market
    #   rate: [BigDecimal]
    #   amount: [BigDecimal] minimal amount is 0.01 BTC
    #   order_type: [String] "sell" or "buy"
    #   ltimestamp: [int] ローカルタイムスタンプ
    def sell(rate, amount=BigDecimal.new(0))
      have_key?
      address = @url_private + "/trade_add/"
      params = {
        "amount" => amount.to_f.round(4),
        "price" => rate.to_i,
        "type" => "sell",
      }
      h = post_ssl(address, params)
      {
        "success"    => h["result"].to_s,
        "id"         => h["id"].to_s,
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

    # Connect to address via https, and return json reponse.
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
      next_nonce = (Time.now.to_i) * 100 % 10_000_000_000

      if next_nonce <= pre_nonce
        @@nonce = pre_nonce + 1
      else
        @@nonce = next_nonce
      end

      return @@nonce
    end

    def get_sign(params)
      secret = Digest::MD5.hexdigest(@api_secret)
      text = URI.encode_www_form(params)

      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, text)
    end

    def post_ssl(address, params={})
      uri = URI.parse(address)
      params["key"] = @api_key
      params["nonce"] = get_nonce
      params["signature"] = get_sign(params)

      begin
        req = Net::HTTP::Post.new(uri)
        req.set_form(params)

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
