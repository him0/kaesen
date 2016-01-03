require './market.rb'
require 'Zaif'

class MyZaif < Market
# Zaif wapper class

  # @param [String] @address the address of Zaif Wallet
  # The address cannot be get with Zaif API.
  # This should be set with Environment Variable.
  # @param [String] @currency_code
  # @param [Zaif::API] @client
  def initialize()
    @name = "Zaif"
    @api_key = ENV["ZAIF_API_KEY"]
    @api_key_secret = ENV["ZAIF_API_KEY_SECRET"]
    @address = ENV["ZAIF_ADDRESS"]
    opts = {
      "api_key":@api_key,
      "api_secret":@api_key_secret
    }
    @currency_code = "btc"
    @client = Zaif::API.new(opts)
    update()
  end

  def update()
    out=""
    t = @client.get_ticker(@currency_code)
    fee = 0 # %
    @raw_ask = t["ask"].to_f
    @ask = @raw_ask * ((100 + fee) / 100)
    @raw_bid = t["bid"].to_f
    @bid = @raw_bid * ((100 - fee) / 100)

    begin  # nonce not incremented error point
      b = @client.get_info()
    rescue
      retry
    end

    @left_jpy = b["funds"]["jpy"].to_f
    @left_btc = b["funds"]["btc"].to_f
    out += @name + " is updated.\n"
    out
  end

  def buy(rate,amount=0)
    @client.bid(@currency_code, rate, amount)
  end

  def sell(rate,amount=0)
    @client.ask(@currency_code, rate, amount)
  end

  def market_buy(amount=0)

  end

  def market_sell(amount=0)

  end

  def send(amount, address)
    @client.withdraw(@currency_code, address, amount)
  end
end