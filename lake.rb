require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'                  # for DateTime

module Bot

  # Lake Wrapper Class
  # https://www.lakebtc.com/s/api
  class Lake < Market

    def initialize()
      super()
      @name        = "Lake"
      @api_key     = ENV["LAKE_KEY"]
      @api_secret  = ENV["LAKE_SECRET"]
      @url_public  = "https://www.LakeBTC.com/api_v1"
      @url_private = @url_public
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
      h = get_ssl(@url_public + "/ticker")
      h = h["JPY"]
      {
          "last"   => N.new(h["last"]),
          "high"   => N.new(h["high"]),
          "low"    => N.new(h["low"]),
          "volume" => N.new(h["vol"].to_s), # to_s がないと誤差が生じる
          "bid"    => N.new(h["bid"]),
          "ask"    => N.new(h["ask"]),
          "ltimestamp" => Time.now.to_i,
      }
    end

    # Connect to address via https, and return json reponse.
    def get_ssl(address)
      uri = URI.parse(address)
      begin
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.open_timeout = 15 # 160214 アクセスに時間がかかる
        https.read_timeout = 15
        # https.verify_mode = OpenSSL::SSL::VERIFY_PEER
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

  end
end
