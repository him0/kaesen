require 'spec_helper'

describe Kaesen::Bitflyer do
  before { @m = Kaesen::Bitflyer.new() }

  it 'should get ticker' do
    test_ticker(@m.ticker)
  end

  it 'should get depth' do
    test_depth(@m.depth)
  end

  it 'should get balance' do
    test_balance(@m.balance)
  end

  # it 'should buy some bitcoin' do
  #   result = @m.buy(30000, 0.001)
  #   print result
  #
  #   expect(result.class).to eq Hash
  #
  #   expect(result["success"].class).to eq String
  #   expect(result["id"].class).to eq String
  #   expect(result["rate"].class).to eq BigDecimal
  #   expect(result["amount"].class).to eq BigDecimal
  #   expect(result["order_type"].class).to eq String
  #   expect(result["ltimestamp"].class).to eq Fixnum
  # end
  #
  # it 'should sell some bitcoin' do
  #   result = @m.sell(60000, 0.001)
  #   print result
  #
  #   expect(result.class).to eq Hash
  #
  #   expect(result["success"].class).to eq String
  #   expect(result["id"].class).to eq String
  #   expect(result["rate"].class).to eq BigDecimal
  #   expect(result["amount"].class).to eq BigDecimal
  #   expect(result["order_type"].class).to eq String
  #   expect(result["ltimestamp"].class).to eq Fixnum
  # end
end
