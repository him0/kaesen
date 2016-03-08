module Kaesen
  class Client
    attr_reader :markets
    attr_reader :ticker
    attr_reader :balance
    attr_reader :depth

    def initialize
      @markets = []   # [Array]:
                      #   [Market] instance of markets
      @tickers = {}   # [Hash]
                      #   [String]: market name
                      #   [Hash]: hash of ticker
      @depths = {}   # [Hash]:
                      #   [String]: market name
                      #   [Hash]: hash of depth
      @balances = {}  # [Hash]:
                      #   [String]: market name
                      #   [Hash]: hash of depth
    end

    # register the instance of market
    # @parm [Market]
    def push(market)
      @markets.push(market)
    end

    # get the instance of market with key
    # @parms [String] market name
    # @return [Market] or nil
    def get(market_name)
      @markets.each{|m|
        return m if m.name == market_name
      }
      return nil
    end

    # Update market information.
    # @return [hash] hash of ticker
    def update_tickers()
      @markets.each{|m|
        @tickers[m.name] = m.ticker
      }
      @tickers
    end

    # Update market information.
    # @return [hash] hash of depth
    def update_depths()
      @markets.each{|m|
        @depths[m.name] = m.depth
      }
      @depths
    end

    # Update asset information.
    # @return [hash] hash of balance
    def update_balances()
      @markets.each{|m|
        @balances[m.name] = m.balance
      }
      @balances
    end
  end
end
