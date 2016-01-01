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
    @client = CoincheckClient.new(@api_key, @api_key_secret)
    a = JSON.parse(@client.read_accounts.body)
    @address = a["bitcoin_address"]
    update()
  end

  def update()
    t = JSON.parse(@client.read_ticker.body)
    @ask = t["ask"].to_f
    @bid = t["bid"].to_f
    b = JSON.parse(@client.read_balance.body)
    @left_jpy = b["jpy"].to_f
    @left_btc = b["btc"].to_f
  end

  def buy(rate,amount=0)
  end

  def sell(rate,amount=0)
  end

  def market_buy(amount=0)

  end

  def market_sell(amount=0)

  end

  def send(amount, address)
    @client.create_send_money(address, amount)
  end
end
