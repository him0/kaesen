require './market.rb'
require 'json'
require 'openssl'
require 'uri'
require 'net/http'
require 'time'

class BitFlyerLightning < Market
# bitFlyerLinghtning wapper class

  # @param [String] @base_rul The base URL of API.
  # @param [String] @api_version The version of API.
  def initialize()
    super()
    @name = "bitFlyerL" # omitted name
    @api_key = ENV["BIT_FLYER_LIGHTNING_API_KEY"]
    @api_key_secret = ENV["BIT_FLYER_LIGHTNING_API_KEY_SECRET"]
    @base_url = "https://lightning.bitflyer.jp"
    @api_version = "v1"

    update()
  end

  def update()
    out = ""
    t = get_ticker()
    @ask = t["best_ask"].to_f
    @bid = t["best_bid"].to_f
    b = get_balance()
    @left_jpy = b[0]["amount"].to_f
    @left_btc = b[1]["amount"].to_f
    out += @name + " is updated.\n"
    out
  end

  def buy(rate,amount=0)
    get_sendchildorder(rate, amount, "BUY", true)
  end

  def sell(rate,amount=0)
    get_sendchildorder(rate, amount, "SELL", true)
  end

  def market_buy(amount=0)

  end

  def market_sell(amount=0)

  end

  def send(amount, address)

  end

  # Get ticker json.
  # @return [json] ticker_json
  def get_ticker()
    ticker_address = "getticker"
    address = (@base_url + "/" +
      @api_version + "/" +
      ticker_address)

    return get_public_json(address)
  end

  # Get a balance json.
  # @return [json] balance_json
  def get_balance()
    balance_address = "me/getbalance"
    address = (@base_url + "/" +
      @api_version + "/" +
      balance_address)

    return get_private_json(address)
  end

  # Get create order.
  # @return [json] sendchildorder_json
  def get_sendchildorder(rate, amount=0, order_type, is_limit_oeder)
    sendchildorder_address = "me/sendchildorder"
    address = (@base_url + "/" +
      @api_version + "/" +
      sendchildorder_address)

    sub_order_type = "MARKET"
    if is_limit_oeder
      sub_order_type = "LIMIT"
    end
    body = '{
      "product_code": "BTC_JPY",
      "child_order_type": "' + sub_order_type + '",
      "side": "' + order_type + '",
      "price": "' + rate.to_s + '",
      "size": "' + amount.to_s + '",
      "minute_to_expire": 525600,
      "time_in_force": "GTC"
    }'
    return post_private_json(address, body)
  end

  # Check the api and api secret.
  # @raise []
  def check_key
    if @api_key.nil? or @api_key_secret.nil?
      raise "You need to set a API key and secret"
    end
  end

  # Connect to public api via https with GET method.
  # @param [String] address
  # @return [json]
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
            raise APIErrorException, json["error"] if json.is_a?(Hash) && json["success"] == 0
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

  # Connect to private api via https with POST method.
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
            raise APIErrorException, json["error"] if json.is_a?(Hash) && json["success"] == 0
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

  def get_timestamp
    time = Time.now.to_i
    return time.to_s
  end

  def get_cool_down
    if @cool_down
      sleep(@cool_down_time)
    end
  end

end