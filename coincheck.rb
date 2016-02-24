require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'

module Bot

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
      @nonce = 0
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
    #   timestamp: [nil]
    #   ltimestamp: [int] ローカルタイムスタンプ
    #   volume: [N] 取引量
    def ticker
      h = get_ssl(@url_public + "/api/ticker")
      {
        "ask"    => N.new(h["ask"]),
        "bid"    => N.new(h["bid"]),
        "last"   => N.new(h["last"]),
        "high"   => N.new(h["high"]),
        "low"    => N.new(h["low"]),
        "timestamp" => h["timestamp"],
        "ltimestamp" => Time.now.to_i,
        "volume" => N.new(h["volume"]), # h["volume"] は String
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
      h = get_ssl(@url_public + "/api/order_books")
      {
        "asks" => h["asks"].map{|a,b| [N.new(a), N.new(b.to_s)]},
        "bids" => h["bids"].map{|a,b| [N.new(a), N.new(b.to_s)]},
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
    def balance
      have_key?
      address = @url_private + "/api/accounts/balance"
      h = get_ssl_with_sign(address)
      {
        "jpy" => {
          "amount" => N.new(h["jpy"]).add(h["jpy_reserved"].to_s),
          "available" => N.new(h["jpy"]),
        },
        "btc" => {
          "amount" => N.new(h["btc"]).add(h["btc_reserved"].to_s),
          "available" => N.new(h["btc"]),
        },
      }
    end

    # Bought the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # Abstract Method.
    # @param [N] rate
    # @param [N] amount
    # @return [hash] history_order_hash
    def buy(rate, amount=N.new(0))
      have_key?
      post_ssl_with_sign(@url_private + "/api/exchange/orders",
                         {
                           "rate" => rate.to_i,
                           "amount" => amount.to_f.round(4),
                           "order_type" => "buy",
                           "pair" => "btc_jpy",
                         })
    end

    # Sell the amount of Bitcoin at the rate.
    # 指数注文 売り.
    # Abstract Method.
    # @param [int] rate
    # @param [float] amount
    # @return [hash] history_order_hash
    def sell(rate, amount=N.new(0))
      have_key?
      post_ssl_with_sign(@url_private + "/api/exchange/orders",
                         {
                         "rate" => rate.to_i,
                         "amount" => amount.to_f.round(4),
                         "order_type" => "sell",
                         "pair" => "btc_jpy",
                         })
    end

    private

    def get_nonce
      pre_nonce = @nonce
      # 桁数揃えないとエラーになる
      next_nonce = (Time.now.to_i) * 100 % 10_000_000_000

      if next_nonce <= pre_nonce
        @@nonce = pre_nonce + 1
      else
        @@nonce = next_nonce
      end

      return @@nonce
    end

    def get_sign(address, nonce, body="")
      text = nonce.to_s + address.to_s + body
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @api_secret, text)
    end

    # Connect to address via https, and return json response.
    def get_ssl(address)
      uri = URI.parse(address)
      begin
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.open_timeout = 5
        https.read_timeout = 15
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        https.verify_depth = 5

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

    # Connect to address via https, and return json response.
    def get_ssl_with_sign(address,body="")
      uri = URI.parse(address)
      nonce = get_nonce
      sign = get_sign(address, nonce, body.to_json)

      begin
        req = Net::HTTP::Get.new(uri)
        req["ACCESS-KEY"] = @api_key
        req["ACCESS-NONCE"] = nonce
        req["ACCESS-SIGNATURE"] = sign
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.open_timeout = 5
        https.read_timeout = 15
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        https.verify_depth = 5

        https.start {|w|
          response = w.request(req)
          case response
            when Net::HTTPSuccess
              json = JSON.parse(response.body)
              raise JSONException, response.body if json == nil
              raise APIErrorException, json["error_message"] if json.is_a?(Hash) && json["status"] != nil
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
      sign = get_sign(address, nonce, body.to_json)

      begin
        req = Net::HTTP::Post.new(uri)
        req["ACCESS-KEY"] = @api_key
        req["ACCESS-NONCE"] = nonce
        req["ACCESS-SIGNATURE"] = sign
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true


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
