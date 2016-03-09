require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'
require 'bigdecimal'

module Kaesen
  # Kaesen Wrapper Class
  # https://www.monetago.com/#/api/
  ## API制限
  ## . More than 500 requests per 10 minutes will result in IP ban.
  ## . For real-time data please refer to the MonetaGo WebSocket API.
  
  class Monetago < Market
    @@nonce = 0

    def initialize()
      super()
      @name        = "Monetago"
      @api_key     = ENV["MONETAGO_KEY"]
      @api_secret  = ENV["MONETAGO_SECRET"]
      @url_public  = "https://api.monetago.com:8400/ajax/v1"
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
      h = post_ssl(@url_public + "/GetTicker", {product_pair: 'BTCJPY'})
      {
        "ask"        => BigDecimal.new(h["ask"].to_s),
        "bid"        => BigDecimal.new(h["bid"].to_s),
        "last"       => BigDecimal.new(h["last"].to_s),
        "high"       => BigDecimal.new(h["high"].to_s),
        "low"        => BigDecimal.new(h["low"].to_s),
        "volume"     => BigDecimal.new(h["volume"].to_s),
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
      h = post_ssl(@url_public + "/GetOrderBook")
      {
        "asks"       => h["asks"].map{|x| [BigDecimal.new(x["px"].to_s), BigDecimal.new(x["qty"].to_s)]},
        "bids"       => h["bids"].map{|x| [BigDecimal.new(x["px"].to_s), BigDecimal.new(x["qty"].to_s)]},
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

    def post_ssl(address, params={})
      uri = URI.parse(address)

      begin
        req = Net::HTTP::Post.new(uri, initheader = {"Content-Type" => "application/json"})
        req.set_form(params)
        req.body = {"productPair" => "BTCJPY"}.to_json

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
