require 'spec_helper'

describe Kaesen::Bitflyerfx do
  before do
    @market = Kaesen::Bitflyerfx.new()
  end

  describe "#ticker" do
    context "normal" do
      it 'should get ticker' do
        ticker = @market.ticker
        print Kaesen::Market.unBigDecimal(ticker)

        expect(ticker.class).to eq Hash
        expect(ticker["ask"].class).to eq BigDecimal
        expect(ticker["bid"].class).to eq BigDecimal
        expect(ticker["last"].class).to eq BigDecimal
        expect(ticker["high"]).to eq nil
        expect(ticker["low"]).to eq nil
        expect(ticker["volume"].class).to eq BigDecimal
        expect(ticker["ltimestamp"].class).to eq Fixnum
        expect(ticker["timestamp"].class).to eq Fixnum
      end
    end
  end

  describe "#depth" do
    context "normal" do
      it 'should get depth' do
        test_depth(@market.depth)
      end
    end
  end

  # describe "#balance" do
  #   context "normal" do
  #     it 'should get balance' do
  #       test_balance(@market.balance)
  #     end
  #   end
  # end

  # describe "#buy" do
  #   context "normal" do
  #     it 'should buy some bitcoin' do
  #       test_oreder_result(@market.buy(30000, 0.001)) # minimal 0.001BTC
  #     end
  #   end
  # end

  # describe "#market_buy" do
  #   context "normal" do
  #     it 'should buy some bitcoin' do
  #       result = @market.market_buy(0.001)
  #       print result
  #
  #       expect(result.class).to eq Hash
  #
  #       expect(result["success"].class).to eq String
  #       expect(result["id"].class).to eq String
  #       expect(result["rate"]).to eq nil
  #       expect(result["amount"].class).to eq BigDecimal
  #       expect(result["order_type"].class).to eq String
  #       expect(result["ltimestamp"].class).to eq Fixnum
  #     end
  #   end
  # end

  # describe "#sell" do
  #   context "normal" do
  #     it 'should sell some bitcoin' do
  #       test_oreder_result(@market.sell(60000, 0.001)) # minimal 0.001BTC
  #     end
  #   end
  # end

  # describe "#market_sell" do
  #   context "normal" do
  #     it 'should sell some bitcoin' do
  #       result = @market.market_sell(0.001)
  #       print result
  #
  #       expect(result.class).to eq Hash
  #
  #       expect(result["success"].class).to eq String
  #       expect(result["id"].class).to eq String
  #       expect(result["rate"]).to eq nil
  #       expect(result["amount"].class).to eq BigDecimal
  #       expect(result["order_type"].class).to eq String
  #       expect(result["ltimestamp"].class).to eq Fixnum
  #     end
  #   end
  # end
end
