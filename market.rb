# @abstract
# Abstruct Class of Exchange Markets.
class Market

  def initialize()
    @name    = "No Setting" # [String] The name of Exchange Market
    @address = "No Setting" # [String] The address of Wallet
    @raw_ask = 0 # [float]  買値
    @ask     = 0 # [float] 買値 + 手数料
    @raw_bid = 0 # [float] 買値 + 手数料
    @bid     = 0 # [float] 売値
    @raw_jpy = 0 # [float] property
    @jpy     = 0 # [float] available
    @raw_btc = 0 # [float] property
    @btc     = 0 # [float] available
  end

  # Update Properties.
  # Abstract Method.
  # @return ?
  def update()
  end

  # Get Total Property.
  # @return [float] property
  def total_prperty
    property = 0
    property += @jpy
    property += @btc * @bid
    property
  end

  # Bought the amount of Bitcoin at the rate.
  # 指数注文 買い.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] history_order_hash
  def buy(rate, amount=0)
  end

  # Sell the amount of Bitcoin at the rate.
  # 指数注文 売り.
  # Abstract Method.
  # @param [int] rate
  # @param [float] amount
  # @return [hash] history_order_hash
  def sell(rate, amount=0)
  end

  # Bought the amount of JPY.
  # Abstract Method.
  # @param [float] market_buy_amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate.
  def market_buy(market_buy_amount=0)
  end

  # Sell the amount of Bitcoin.
  # Abstract Method.
  # @param [float] amount
  # @return [hash] history_order_hash
  # "jpy" -> amount of jpy.
  # "btc" -> amount of btc.
  # "rate" -> exchange rate.
  def market_sell(amount=0)
  end

  # Send amount of Bitcoint to address.
  # Abstract Method.
  # @param [float] amount
  # @param [String] address
  # @return ?
  def send(amount=0, address)
  end

  attr_reader :name
  attr_reader :address
  attr_reader :raw_ask
  attr_reader :ask
  attr_reader :raw_bid
  attr_reader :bid
  attr_reader :raw_jpy
  attr_reader :jpy
  attr_reader :raw_btc
  attr_reader :btc
end
