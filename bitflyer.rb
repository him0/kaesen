require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'                  # for DateTime

module Bot

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
    #   timestampl: [int] ローカルタイムスタンプ
    #   volume: [N] 取引量
    def ticker
      h = get_ssl(@url_public + "/getticker?product_code=BTC_JPY")
      {
        "ask"        => N.new(h["best_ask"]),
        "bid"        => N.new(h["best_bid"]),
        "last"       => N.new(h["ltp"]),         # ltp は last price ?
        # "high" is not supply
        # "low" is not supply
        "timestamp"  => DateTime.parse(h["timestamp"]).strftime('%s').to_i,
        "ltimestamp" => Time.now.to_i,
        "volume"     => N.new(h["volume"].to_s) # to_s にしないと誤差が生じる
      }
    end

    # Get order book.
    # @return [hash] array of market depth
    def depth
      h = get_ssl(@url_public + "/getboard?product_code=BTC_JPY")
      {
        "asks" => h["asks"].map{|x| [N.new(x["price"].to_s), N.new(x["size"].to_s)]},
        "bids" => h["bids"].map{|x| [N.new(x["price"].to_s), N.new(x["size"].to_s)]},
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
      address = @url_private + "/me/getbalance"
      h = get_ssl_with_sign(address)
      {
        "jpy" => {
          "amount" => N.new(h[0]["amount"]),
          "available" => N.new(h[0]["available"]),
        },
        "btc" => {
          "amount" => N.new(h[1]["amount"]),
          "available" => N.new(h[1]["available"]),
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
      address = (@url_private + "/me/sendchildorder")
      body = {
        "product_code"     => "BTC_JPY",
        "child_order_type" => "LIMIT",
        "side"             => "BUY",
        "price"            => rate.to_i,
        "size"             => amount.to_f.round(4),
        "minute_to_expire" => 525600,
        "time_in_force"    => "GTC",
      }.to_json
      post_ssl_with_sign(address, body)
    end

    # Sell the amount of Bitcoin at the rate.
    # 指数注文 売り.
    # Abstract Method.
    # @param [int] rate
    # @param [float] amount
    # @return [hash] history_order_hash
    def sell(rate, amount=N.new(0))
      have_key?
      address = (@url_private + "/me/sendchildorder")
      body = {
        "product_code"     => "BTC_JPY",
        "child_order_type" => "LIMIT",
        "side"             => "SELL",
        "price"            => rate.to_i,
        "size"             => amount.to_f.round(4),
        "minute_to_expire" => 525600,
        "time_in_force"    => "GTC",
      }.to_json
      post_ssl_with_sign(address, body)
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

    def get_sign(uri, method, nonce, body="")
      text = nonce.to_s + method + uri.request_uri + body
      secret = @api_secret

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
        req.body = body

        https = https = initialize_https(uri)
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
      headers = get_headers(uri, "POST", nonce, body)

      begin
        req = Net::HTTP::Post.new(uri, headers)
        req.body = body

        https = initialize_https(uri)
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

  end
end
