require './market.rb'
require 'Zaif'

# Zaif Wrapper Class
class MyZaif < Market

  def initialize()
    super()
    @name           = "Zaif"
    @api_key        = ENV["ZAIF_API_KEY"]
    @api_key_secret = ENV["ZAIF_API_KEY_SECRET"]
    @address        = ENV["ZAIF_ADDRESS"]
    @fee_rate       = 0 # %
    @currency_code = "btc"
    opts = {
      "api_key":    @api_key,
      "api_secret": @api_key_secret
    }
    @client = Zaif::API.new(opts)
    update()
  end

  # Update Properties.
  # Abstract Method.
  # @return ?
  def update()
    t = @client.get_ticker(@currency_code)
    @raw_ask = t["ask"].to_f
    @ask = @raw_ask * ((100 + @fee_rate) / 100)
    @raw_bid = t["bid"].to_f
    @bid = @raw_bid * ((100 - @fee_rate) / 100)

    begin  # nonce not incremented error point
      b = @client.get_info()
    rescue
      retry
    end

    @jpy = b["funds"]["jpy"].to_f
    @btc = b["funds"]["btc"].to_f
  end

  # Bought the amount of Bitcoin at the rate.
  # 指数注文 買い.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] history_order_hash
  def buy(rate, amount=0)
    @client.bid(@currency_code, rate.to_i, amount)
  end

  # Sell the amount of Bitcoin at the rate.
  # 指数注文 売り.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] history_order_hash
  def sell(rate, amount=0)
    @client.ask(@currency_code, rate.to_i, amount)
  end

  # Bought the amount of JPY.
  # Abstract Method.
  # @param [float] market_buy_amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate.
  # [todo] update
  def market_buy(market_buy_amount=0)
    amount = market_buy_amount / @bid
    @client.bid(@currency_code, @bid*1.1, amount)
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
    @client.ask(@currency_code, @ask*1.1, amount)
  end

  # Send amount of Bitcoint to address.
  # Abstract Method.
  # @param [float] amount
  # @param [String] address
  # @return ?
  def send(amount=0, address)
    @client.withdraw(@currency_code, address, amount)
  end
end