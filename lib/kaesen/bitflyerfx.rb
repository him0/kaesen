require_relative 'market.rb'
require 'net/http'
require 'openssl'
require 'json'
require 'date'
require 'bigdecimal'

module Kaesen
  # BitFlyer FX Wrapper Class
  # https://lightning.bitflyer.jp/docs?lang=ja
  ## API制限
  ## . Private API は 1 分間に約 200 回を上限とします。
  ## . IP アドレスごとに 1 分間に約 500 回を上限とします。

  class Bitflyerfx < Bitflyer
    def initialize(options = {})
      super()
      @name        = "BitFlyerFX"
      @product_code = "FX_BTC_JPY"

      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      yield(self) if block_given?
    end

    def balance
      raise NotImplemented.new() # getcollateral
    end
  end
end
