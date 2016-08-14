require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'bigdecimal'

module Kaesen
  # Quoine Wrapper Class
  # https://developers.quoine.com/
  ## API制限
  # API users should not make more than 300 requests per 5 minute. Requests go beyond the limit will return with a 429 status 
  
  class Quoine < Market
    @@nonce = 0

    def initialize(options = {})
      super()
      @name        = "Quoine"
      @api_key     = ENV["QUOINE_KEY"]
      @api_secret  = ENV["QUOINE_SECRET"]
      @url_public  = "https://api.quoine.com"
      @url_private = @url_public

      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      yield(self) if block_given?
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
      h = get_ssl(@url_public + "/products/code/CASH/BTCJPY") # the id of BTCJPY is 5.
      {
        "ask"        => BigDecimal.new(h["market_ask"].to_s),
        "bid"        => BigDecimal.new(h["market_bid"].to_s),
        "last"       => BigDecimal.new(h["last_traded_price"].to_s),
        # "high"
        # "low"
        "volume"     => BigDecimal.new(h["volume_24h"].to_s), # of the previous 24 hours
        "ltimestamp" => Time.now.to_i,
        # "vwap"
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
      h = get_ssl(@url_public + "/products/5/price_levels") # the id of BTCJPY is 5.
      {
        "asks"       => h["buy_price_levels"].map{|a,b| [BigDecimal.new(a.to_s), BigDecimal.new(b.to_s)]}, # to_s でないと誤差が生じる
        "bids"       => h["sell_price_levels"].map{|a,b| [BigDecimal.new(a.to_s), BigDecimal.new(b.to_s)]}, # to_s でないと誤差が生じる
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
      next_nonce = (Time.now.to_i) * 100

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
