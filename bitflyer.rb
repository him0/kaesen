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

    def initialize()
      super()
      @name        = "BitFlyer"
      @api_key     = ENV["BITFLYER_KEY"]
      @api_secret  = ENV["BITFLYER_SECRET"]
      @url_public  = "https://api.bitflyer.jp/v1"
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
      h = get_ssl(@url_public + "/getticker?product_code=BTC_JPY")
      {
        "ask"    => N.new(h["best_ask"]),
        "bid"    => N.new(h["best_bid"]),
        "last"   => N.new(h["ltp"]),         # ltp は last price ?
        # "high" is not supply
        # "low" is not supply
        "timestamp" => DateTime.parse(h["timestamp"]).strftime('%s').to_i,
        "ltimestamp" => Time.now.to_i,
        "volume" => N.new(h["volume"].to_s) # to_s にしないと誤差が生じる
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
