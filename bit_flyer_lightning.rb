require './market.rb'
require 'json'
require 'openssl'
require 'uri'
require 'net/http'

# bitFlyerLinghtning Wrapper Class
class BitFlyerLightning < Market

  def initialize()
    super()
    @name           = "bitFlyerL"
    @api_key        = ENV["BIT_FLYER_LIGHTNING_API_KEY"]
    @api_key_secret = ENV["BIT_FLYER_LIGHTNING_API_KEY_SECRET"]
    @base_url       = "https://lightning.bitflyer.jp"
    @api_version    = "v1"
    @fee_rate       = 0 # %
  end

  # Update Properties.
  # Abstract Method.
  # @return ?
  def update()
    t = get_ticker()
    @raw_ask = t["best_ask"].to_f
    @ask = @raw_ask * ((100 + @fee_rate) / 100)
    @raw_bid = t["best_bid"].to_f
    @bid = @raw_bid * ((100 - @fee_rate) / 100)
    b = get_balance()
    @jpy = b[0]["available"].to_f
    @btc = b[1]["available"].to_f
  end

  # Bought the amount of Bitcoin at the rate.
  # 指数注文 買い.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] history_order_hash
  def buy(rate, amount=0)
    get_sendchildorder(rate, amount, "BUY")
  end

  # Sell the amount of Bitcoin at the rate.
  # 指数注文 売り.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] history_order_hash
  def sell(rate, amount=0)
    get_sendchildorder(rate, amount, "SELL")
  end

  # Bought the amount of JPY.
  # Abstract Method.
  # @param [float] market_buy_amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate.
  # [todo] update
  def market_buy(amount=0)
    r = get_sendchildorder(rate, amount, "BUY", "MARKET")
    id = r["parent_order_acceptance_id"]
  end

  # Sell the amount of Bitcoin.
  # Abstract Method.
  # @param [float] amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate.
  # [todo] update
  def market_sell(amount=0)
    get_sendchildorder(rate, amount, "BUY", "MARKET")
  end

  # Send amount of Bitcoint to address.
  # Abstract Method.
  # @param [float] amount
  # @param [String] address
  # @return ?
  # 機能がない
  def send(amount, address)
    raise NoImpimentException
  end

  # Get ticker json.
  # @return [hash] ticker_hash
  def get_ticker()
    ticker_address = "getticker"
    address = (@base_url + "/" +
               @api_version + "/" +
               ticker_address)
    get_public_json(address)
  end

  # Get a balance json.
  # @return [hash] balance_hash
  def get_balance()
    balance_address = "me/getbalance"
    address = (@base_url + "/" +
               @api_version + "/" +
               balance_address)
    get_private_json(address)
  end

  # Get create order.
  # @param [int] rate
  # @param [float] amount
  # @param [String] order_type
  # @param [String] sub_order_type
  # @return [hash] order_result_hash
  def get_sendchildorder(rate, amount=0, order_type="BUY", sub_order_type="LIMIT")
    sendchildorder_address = "me/sendchildorder"
    address = (@base_url + "/" +
               @api_version + "/" +
               sendchildorder_address)
    body = {
      "product_code": "BTC_JPY",
      "child_order_type": sub_order_type,
      "side": order_type,
      "price": rate.to_i.to_s,
      "size": amount.to_s,
      "minute_to_expire": 525600,
      "time_in_force": "GTC"
    }.to_json
    post_private_json(address, body)
  end

  # Connect to public api via https with GET method.
  # @param [String] address
  # @return [hash] result_hash
  # @raise []
  def get_public_json(address)
    uri = URI.parse(address)
    begin
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 5
      https.read_timeout = 15

      https.start {|w|
        response = w.get(uri.request_uri)
        case response
          when Net::HTTPSuccess
            json = JSON.parse(response.body)
            raise JSONException, response.body if json == nil
            raise APIErrorException, json["error"] if json.is_a?(Hash) && json.has_key?("error")
            get_cool_down
            return json
          else
            raise ConnectionFailedException, "Failed to connect to bitFlyer Lightning."
        end
      }
    rescue
      raise
    end
  end

  # Connect to private api via https with GET method.
  # @param [String] address
  # @param [String] body
  # @return [hash] result_hash
  # @raise []
  def get_private_json(address, body="")
    check_key

    uri = URI.parse(address)
    method = "GET"
    timestamp = get_timestamp()
    text = timestamp + method + uri.request_uri + body
    key = @api_key
    secret = @api_key_secret
    sign = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, text)

    begin
      req = Net::HTTP::Get.new(uri, initheader={
        "ACCESS-KEY" => key,
        "ACCESS-TIMESTAMP" => timestamp,
        "ACCESS-SIGN" => sign,
        "Content-Type" => "application/json"
      })
      req.body = body

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 5
      https.read_timeout = 15

      https.start {|w|
        response = w.request(req)
        case response
          when Net::HTTPSuccess
            json = JSON.parse(response.body)
            raise JSONException, response.body if json == nil
            raise APIErrorException, json["error_message"] if json.is_a?(Hash) && json["status"] != nil
            get_cool_down
            return json
          else
            raise ConnectionFailedException, "Failed to connect to bitFlyer Lightning: " + response.value
        end
      }
    rescue Net::HTTPServerException
      retry
    rescue
      raise
    end
  end

  # Connect to private api via https with POST method.
  # @param [String] address
  # @param [String] body
  # @return [hash] result_hash
  # @raise []
  def post_private_json(address, body)
    check_key

    uri = URI.parse(address)
    method = "POST"
    timestamp = get_timestamp()
    text = timestamp + method + uri.request_uri + body
    key = @api_key
    secret = @api_key_secret
    sign = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, text)

    begin
      req = Net::HTTP::Post.new(uri, initheder={
        "ACCESS-KEY" => key,
        "ACCESS-TIMESTAMP" => timestamp,
        "ACCESS-SIGN" => sign,
        "Content-Type" => "application/json"
      })
      req.body = body

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      https.open_timeout = 5
      https.read_timeout = 15

      https.start {|w|
        response = w.request(req)
        case response
          when Net::HTTPSuccess
            json = JSON.parse(response.body)
            raise JSONException, response.body if json == nil
            raise APIErrorException, json["error_message"] if json["status"] != nil
            get_cool_down
            return json
          else
            raise ConnectionFailedException, "Failed to connect to bitFlyer Lightning: " + response.value
        end
      }
    rescue
      raise
    end
  end

  # Check the api and api secret.
  def check_key
    raise "You need to set a API key and secret" if @api_key.nil? or @api_key_secret.nil?
  end

  # get nonce
  def get_timestamp
    Time.now.to_i.to_s
  end

  # get cool down
  def get_cool_down
    sleep(@cool_down_time) if @cool_down
  end

  class ConnectionFailedException < StandardError; end
  class APIErrorException < StandardError; end
  class JSONException < StandardError; end
  class NoImpimentException < StandardError; end

end