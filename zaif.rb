require_relative 'market.rb'
require 'Zaif'

module Bot

  # Zaif Wrapper Class
  # https://corp.zaif.jp/api-docs/
  class Zaif < Market

    def initialize()
      # super()
      @name            = "Zaif"
      @api_key         = ENV["ZAIF_API_KEY"]
      @api_secret      = ENV["ZAIF_API_SECRET"]
      @zaif_public_url = "https://api.zaif.jp/api/1/"
      @zaif_trade_url  = "https://api.zaif.jp/tapi"
      # update()
    end

    # Get ticker.
    # @return [json]
    def get_ticker
      h = get_ssl(@zaif_public_url + "ticker/btc_jpy")
      {
          "last" => BigDecimal(h["last"],1),
          "high" => BigDecimal(h["high"],1),
          "low"  => BigDecimal(h["low"],1),
          "vwap" => BigDecimal(h["vwap"],4),
          "volume" => BigDecimal(h["volume"],3),
          "bid"  => BigDecimal(h["bid"],1),
          "ask"  => BigDecimal(h["ask"],1),
          "timestamp" => Time.now.to_i,
      }
    end


    # Update market information.
    # @abstract
    # @return ?
    def update
      @ticker = get_ticker
    end

    # Bought the amount of Bitcoin at the rate.
    # 指数注文 買い.
    # Abstract Method.
    # @param [BigDecimal] rate
    # @param [BigDecimal] amount
    # @return [hash] history_order_hash
    def buy(rate, amount=BigDecimal(0))
      have_key?
      post_ssl(@zaif_trade_url,
               "trade",
               {
                   "currency_pair" => "btc_jpy",
                   "action" => "bid",
                   "price" => rate.to_i,
                   "amount" => amount.to_f.round(4),
#                   "limit" => ???,
               })
    end

    # Sell the amount of Bitcoin at the rate.
    # 指数注文 売り.
    # Abstract Method.
    # @param [int] rate
    # @param [float] amount
    # @return [hash] history_order_hash
    def sell(rate, amount=BigDecimal(0))
      have_key?
      post_ssl(@zaif_trade_url,
               "trade",
               {
                   "currency_pair" => "btc_jpy",
                   "action" => "ask",
                   "price" => rate.to_i,
                   "amount" => amount.to_f.round(4),
                   #                   "limit" => ???,
               })
    end

    private

    def get_nonce
      Time.now.to_i
    end

    # Connect to address via https, and return json reponse.
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
              raise APIErrorException, json["error"] if json.is_a?(Hash) && json.has_key?("error")
              return json
            else
              raise ConnectionFailedException, "Failed to connect to zaif."
          end
        }
      rescue
        raise
      end
    end

    # Connect to address via https, and return json reponse.
    def post_ssl(address, method, data, opt = {})
      uri = URI.parse(address)
      data["method"] = method
      data["nonce"] = get_nonce
      begin
        req = Net::HTTP::Post.new(uri)
        req.set_form_data(data)
        req["Key"] = @api_key
        req["Sign"] = OpenSSL::HMAC::hexdigest(OpenSSL::Digest.new('sha512'), @api_secret, req.body)

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
              raise APIErrorException, json["error"] if json.is_a?(Hash) && json["success"] == 0
              return json["return"]
            else
              raise ConnectionFailedException, "Failed to connect to zaif: " + response.value
          end
        }
      rescue
        raise
      end
    end

  end
end
