require 'spec_helper'

describe Kaesen::Client do
  describe "#update_tickers" do
    before do
      @client = Kaesen::Client.new()
    end
    context "num of markets is 0" do
      it "size of hash should be 0" do
        t = @client.update_tickers
        print t
        expect(t.class).to eq Hash
        expect(t.size).to eq 0
      end
    end
    context "num of markets is 1" do
      it "size of hash should be 1" do
        @client.push(Kaesen::Coincheck.new())
        t = @client.update_tickers
        print t
        expect(t.class).to eq Hash
        expect(t.size).to eq 1
      end
    end
    context "num of markets is some" do
      it "size of hash should be some" do
        @client.push(Kaesen::Bitflyer.new())
        @client.push(Kaesen::Btcbox.new())
        t = @client.update_tickers
        print t
        expect(t.class).to eq Hash
        expect(t.size).to eq 2
      end
    end
  end

  describe "#update_depths" do
    before do
      @client = Kaesen::Client.new()
    end
    context "num of markets is 0" do
      it "size of hash should be 0" do
        d = @client.update_depths
        print d
        expect(d.class).to eq Hash
        expect(d.size).to eq 0
      end
    end
    context "num of markets is 1" do
      it "size of hash should be 1" do
        @client.push(Kaesen::Coincheck.new())
        d = @client.update_depths
        print d
        expect(d.class).to eq Hash
        expect(d.size).to eq 1
      end
    end
    context "num of markets is some" do
      it "size of hash should be some" do
        @client.push(Kaesen::Bitflyer.new())
        @client.push(Kaesen::Btcbox.new())
        d = @client.update_depths
        print d
        expect(d.class).to eq Hash
        expect(d.size).to eq 2
      end
    end
  end

  describe "#update_balances" do
    before do
      @client = Kaesen::Client.new()
    end
    context "num of markets is 0" do
      it "size of hash should be 0" do
        b = @client.update_balances
        print b
        expect(b.class).to eq Hash
        expect(b.size).to eq 0
      end
    end
    context "num of markets is 1" do
      it "size of hash should be 1" do
        @client.push(Kaesen::Coincheck.new())
        b = @client.update_balances
        print b
        expect(b.class).to eq Hash
        expect(b.size).to eq 1
      end
    end
    context "num of markets is some" do
      it "size of hash should be some" do
        @client.push(Kaesen::Bitflyer.new())
        @client.push(Kaesen::Btcbox.new())
        b = @client.update_balances
        print b
        expect(b.class).to eq Hash
        expect(b.size).to eq 2
      end
    end

    describe "get the market" do
      before do
        @client = Kaesen::Client.new()
        @client.push(Kaesen::Bitflyer.new())
      end
      context do
        it "shoud return a instance of market" do
          b1 = Kaesen::Bitflyer.new()
          b2 = @client.get(b1.name)

          expect(b1).to_not eq b2
          expect(b1.class).to eq b2.class
        end
      end
    end
  end
end