require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'
require 'bigdecimal'

module Kaesen
  # BitFlyer FX Wrapper Class
  # https://coincheck.jp/documents/exchange/api?locale=ja
  ## API制限
  ## . Private API は 1 分間に約 200 回を上限とします。
  ## . IP アドレスごとに 1 分間に約 500 回を上限とします。
  
  class Bitflyerfx < Bitflyer
    def initialize
      super()
      @name        = "BitFlyerFX"
      @product_code = "FX_BTC_JPY"
    end

    def balance
      raise NotImplemented.new() # getcollateral
    end
  end
end
