require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'                  # for DateTime

module Bot

  # Lake Wrapper Class
  # https://www.kraken.com/en-us/help/api
  class Kraken < Market

    def initialize()
      super()
      @name        = "Kraken"
      @api_key     = ENV["KRAKEN_KEY"]
      @api_secret  = ENV["KRAKEN_SECRET"]
      @url_public  = "https://api.kraken.com/0/public"
      @url_private = "https://api.kraken.com/0/private"
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
      h = get_ssl(@url_public + "/Ticker?pair=XBTJPY")
      h = h["XXBTZJPY"]
      {
          "last"   => N.new(h["c"][0]),
          "high"   => N.new(h["h"][1]),
          "low"    => N.new(h["l"][1]),
          "volume" => N.new(h["v"][1]),
          "bid"    => N.new(h["b"][0]),
          "ask"    => N.new(h["a"][0]),
          "ltimestamp" => Time.now.to_i,
          "vwap"   => N.new(h["p"][1]),
      }
    end

    # Connect to address via https, and return json reponse.
    def get_ssl(address)
      uri = URI.parse(address)
      begin
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.open_timeout = 5
        https.read_timeout = 15
        # https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        https.verify_depth = 5

        https.start {|w|
          response = w.get(uri.request_uri)
          case response
            when Net::HTTPSuccess
              json = JSON.parse(response.body)
              raise JSONException, response.body if json == nil
              raise APIErrorException, json["error"] if json.is_a?(Hash) && json["error"].length > 0
              return json["result"]
            else
              raise ConnectionFailedException, "Failed to connect to #{@name}."
          end
        }
      rescue
        raise
      end
    end

  end
end
