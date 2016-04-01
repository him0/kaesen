require "kaesen/version"
require "kaesen/bitflyer"
require "kaesen/bitflyerfx"
require "kaesen/btcbox"
require "kaesen/coincheck"
require "kaesen/zaif"
require "kaesen/monetago"
require "kaesen/kraken"
require "kaesen/quoine"
require "kaesen/lakebtc"
require "kaesen/client"

# A module of the united wrapper for exchanging Japanese yen and Bitcoin and
# collecting market information of any exchange markets that provide ordinary
# customers with API access.
module Kaesen
end

# Pretty printer for data including BigDecimal
# @param [any] data that may include BigDecimal
# @return [any] data that does not include BigDecimal
def unBigDecimal(x)
  if x.is_a?(Array)
    x.map{|y| unBigDecimal(y)}
  elsif x.is_a?(Hash)
    x.map{|k,v|
      [k, unBigDecimal(v)]
    }.to_h
  elsif x.is_a?(BigDecimal)
    x.to_f
  else
    x
  end
end
