require 'spec_helper'

describe Kaesen::Coincheck do
  before do
    @market = Kaesen::Coincheck.new()
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
        expect(ticker["high"].class).to eq BigDecimal
        expect(ticker["low"].class).to eq BigDecimal
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

  describe "#balance" do
    context "normal" do
      it 'should get balance' do
        test_balance(@market.balance)
      end
    end
  end

  describe "#opens" do
    context "normal" do
      it 'get open orders' do
        test_opens(@market.opens)
      end
    end
  end

  # describe "#buy" do
  #   context "normal" do
  #     it 'should buy some bitcoin' do
  #       test_oreder_result(@market.buy(30000, 0.005)) # minimal 0.005BTC
  #     end
  #   end
  # end

  # describe "#market_buy" do
  #   context "normal" do
  #     it 'should buy some bitcoin' do
  #       test_oreder_result(@market.market_buy(0.005 * 30000))
  #     end
  #   end
  # end

  # describe "#sell" do
  #   context "normal" do
  #     it 'should sell some bitcoin' do
  #       test_oreder_result(@market.sell(60000, 0.005)) # minimal 0.005BTC
  #     end
  #   end
  # end

  # describe "#market_sell" do
  #   context "normal" do
  #     it 'should sell some bitcoin' do
  #       test_oreder_result(@market.market_sell(0.005))
  #     end
  #   end
  # end
end
