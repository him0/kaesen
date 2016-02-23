require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'                  # for DateTime

module Bot

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
      h = get_ssl(@url_public + "/ticker")
      {
        "ask"    => N.new(h["sell"]),
        "bid"    => N.new(h["buy"]),
        "last"   => N.new(h["last"]),
        "high"   => N.new(h["high"]),
        "low"    => N.new(h["low"]),
        # "timestamp" is not supply
        "ltimestamp" => Time.now.to_i,
        "volume" => N.new(h["vol"].to_s), # to_s がないと誤差が生じる
      }
    end

    # Get order book.
    # @return [hash] array of market depth
    def depth
      h = get_ssl(@url_public + "/depth")
      {
        "asks" => h["asks"].map{|a,b| [N.new(a), N.new(b.to_s)]}, # to_s でないと誤差が生じる
        "bids" => h["bids"].map{|a,b| [N.new(a), N.new(b.to_s)]}, # to_s でないと誤差が生じる
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
      address = @url_private + "/balance/"
      h = post_ssl(address)
      {
        "jpy" => {
          "amount" => N.new(h["jpy_balance"].to_s).add(h["jpy_lock"].to_s),
          "available" => N.new(h["jpy_balance"].to_s),
        },
        "btc" => {
          "amount" => N.new(h["btc_balance"].to_s).add(h["btc_lock"].to_s),
          "available" => N.new(h["btc_balance"].to_s),
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
      address = @url_private + "/trade_add/"
      post_ssl(address, params = {
        "amount" => amount.to_f.round(4),
        "price" => rate.to_i,
        "type" => "buy",
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
      address = @url_private + "/trade_add/"
      post_ssl(address, params = {
        "amount" => amount.to_f.round(4),
        "price" => rate.to_i,
        "type" => "sell",
      })
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

    def post_ssl(address, params={})
      uri = URI.parse(address)
      params["key"] = @api_key
      params["nonce"] = get_nonce
      key = Digest::MD5.hexdigest(@api_secret)
      data = URI.encode_www_form(params)
      sign = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), key, data)
      params["signature"] = sign

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
