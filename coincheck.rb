require './market.rb'
require 'ruby_coincheck_client'

class Coincheck < Market
# Coincheck wapper class

  # @param [CoincheckClient] @client
  def initialize()
    super()
    @name = "Coincheck"
    @api_key = ENV['COINCHECK_API_KEY']
    @api_key_secret = ENV['COINCHECK_API_KEY_SECRET']

    @cool_down = true
    @cool_down_time = 2

    @client = CoincheckClient.new(@api_key, @api_key_secret)
    a = JSON.parse(@client.read_accounts.body)
    @address = a["bitcoin_address"] # private
    get_cool_down
    update()
  end

  def update()
    out = ""
    t = JSON.parse(@client.read_ticker.body)
    @ask = t["ask"].to_f
    @bid = t["bid"].to_f
    b = JSON.parse(@client.read_balance.body) # private
    get_cool_down
    @left_jpy = b["jpy"].to_f
    @left_btc = b["btc"].to_f
    out += @name + " is updated.\n"
    out
  end

  def buy(rate,amount=0)
    r = @client.create_orders(
             order_type: "buy",
             rate: rate,
             amount: amount
    )
    get_cool_down
    JSON.parse(r.body)
  end

  def sell(rate,amount=0)
    r = @client.create_orders(
      order_type: "sell",
      rate: rate,
      amount: amount
    )
    get_cool_down
    JSON.parse(r.body)
  end

  def market_buy(market_buy_amount=0)
    r = @client.create_orders(
      order_type: "sell",
      rate: rate,
      amount: amount
    )
    get_cool_down
    JSON.parse(r.body)
  end

  def market_sell(amount=0)
    r = ""
    get_cool_down
    JSON.parse(r.body)
  end

  def send(amount, address)
    r = @client.create_send_money(address, amount)
    get_cool_down
    JSON.parse(r.body)
  end

  def get_cool_down
    if @cool_down
      sleep(@cool_down_time)
    end
  end
end
