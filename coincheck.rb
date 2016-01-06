require './market.rb'
require 'ruby_coincheck_client'

# Coincheck Wrapper Class
class Coincheck < Market

  def initialize()
    super()
    @name           = "Coincheck"
    @api_key        = ENV['COINCHECK_API_KEY']
    @api_key_secret = ENV['COINCHECK_API_KEY_SECRET']
    @fee_rate       = 0.15 # %
    @cool_down      = true
    @cool_down_time = 2

    @client = CoincheckClient.new(@api_key, @api_key_secret)
    a = JSON.parse(@client.read_accounts.body)
    @address = a["bitcoin_address"] # private api
    update()
  end

  # Update Properties.
  # Abstract Method.
  # @return ?
  def update()
    t = JSON.parse(@client.read_ticker.body) # public api
    @raw_ask = t["ask"].to_f
    @ask = @raw_ask * ((100 + @fee_rate) / 100)
    @raw_bid = t["bid"].to_f
    @bid = @raw_bid * ((100 - @fee_rate) / 100)

    b = JSON.parse(@client.read_balance.body) # private
    @jpy = b["jpy"].to_f
    @btc = b["btc"].to_f
  end

  # Bought the amount of Bitcoin at the rate.
  # 指数注文 買い.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] order_result_hash
  def buy(rate, amount=0)
    r = @client.create_orders(
             order_type: "buy",
             rate: rate,
             amount: amount
    )
    JSON.parse(r.body)
  end

  # Bought the amount of Bitcoin at the rate.
  # 指数注文 買い.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] order_result_hash
  def sell(rate, amount=0)
    r = @client.create_orders(
      order_type: "sell",
      rate: rate,
      amount: amount
    )
    JSON.parse(r.body)
  end

  # Buy amount of Bitcoin from Market.
  # @param [float] market_buy_amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate
  def market_buy(market_buy_amount=0)
    r = @client.create_orders(
      order_type: "market_buy",
      market_buy_amount: market_buy_amount
    )
    result = JSON.parse(r.body)
    id = result["id"]
    get_history(id)
  end

  # Sell amount of Bitcoin from Market.
  # @param [float] amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate
  def market_sell(amount=0)
    r = @client.create_orders(
      order_type: "market_sell",
      amount: amount
    )
    result = JSON.parse(r.body)
    id = result["id"]
    get_history(id)
  end

  # Get history and return history_order_json
  # @param [int] id
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate
  def get_history(id)
    h = @client.read_transactions()
    history = JSON.parse(h.body)["transactions"]
    jpy = 0
    btc = 0
    rate = 0
    history.each{|h|
      if h["order_id"] = id.to_s
        jpy = h["funds"]["jpy"]
        btc = h["funds"]["btc"]
        rate = h["rate"]
      end
    }
    {
      "jpy"=> jpy,
      "btc"=> btc,
      "rate"=> rate
    }
  end

  # Send amount of Bitcoint to address.
  # Abstract Method.
  # @param [float] amount
  # @param [String] address
  # @return [hash] result_hash
  def send(amount, address)
    r = @client.create_send_money(address, amount)
    get_cool_down
    JSON.parse(r.body)
  end

  # Get cool down
  def get_cool_down
    sleep(@cool_down_time) if @cool_down
  end
end
