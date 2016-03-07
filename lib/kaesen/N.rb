require 'bigdecimal'

module Kaesen
  class N < BigDecimal
    # @param [String], [Bignum], [Float], [Rational], or [BigDecimal]
    # @return [N]
    def initialize(s,n = 0)
      super(s,n) # 「n が 0 または省略されたときは、n の値は s の有効桁数とみなされます。」
    end

    # @param [String], [Bignum], [Float], [Rational], or [BigDecimal]
    # @return [N]
    def add(s)
      initialize(self.to_s + "+" + s.to_s)
    end

    def inspect
      self.to_s("F")
    end
  end
end
