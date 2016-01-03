class Market
# Abstruct Class of Exchange Markets.

  # @param [String] @name The name of Exchange Market
  # @param [String] @address The address of Wallet
  # @param [String] @api_key
  # @param [String] @api_key_secret
  # @param [float] @ask 買値
  # @param [float] @bid 売値
  # @param [float] @left_jpy
  # @param [float] @left_btc
  def initialize()
    @name = "no set"
    @address = "no set"
    @api_key = ""
    @api_key_secret = ""
    @raw_ask = 0
    @ask = 0
    @raw_bid = 0
    @bid = 0
    @left_jpy = 0
    @left_btc = 0
  end

  # Update Properties.
  def update()
  end

  # Total Property
  # @return [float] property
  def total_prperty
    property = 0
    property += @left_jpy
    property += @left_btc * @raw_bid
    property
  end

  # Bought the amount of Bitcoin at the rate.
  # 指数注文 買い
  # @param [int] rate
  # @param [float] amount
  def buy(rate, amount=0)
  end

  # Sell the amount of Bitcoin at the rate.
  # 指数注文 売り
  # @param [int] rate
  # @param [float] amount
  def sell(rate, amount=0)
  end

  # Bought the amount of JPY.
  # @param [float] market_buy_amount
  def market_buy(market_buy_amount=0)

  end

  # Sell the amount of Bitcoin.
  # @param [float] amount
  def market_sell(amount=0)

  end

  # Send amount of Bitcoint to address.
  # @param [float] amount
  # @param [String] address
  def send(amount=0, address)
  end

  attr_reader :name
  attr_reader :address
  attr_reader :ask
  attr_reader :raw_ask
  attr_reader :bid
  attr_reader :raw_bid
  attr_reader :left_jpy
  attr_reader :left_btc
end
