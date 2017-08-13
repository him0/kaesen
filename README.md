# Kaesen (beta version)

A module of the united wrapper for exchanging Japanese yen and Bitcoin and collecting market information of any exchange markets that provide ordinary customers with API access.

日本国内のビットコインの取引所の API を統一された API で操作できる統合 API ラッパーです．

## Installation

For each of your applications, add the following line to the application's Gemfile:

```ruby
gem 'kaesen'
```

Then, run bundler:

    $ bundle install

or

```shell
gem install kaesen
```

## Usage

```
require 'kaesen'
b =  Kaesen::Bitflyer.new do |config|
  config.api_key = "XXX"
  config.api_secret = "YYY"
end
b.ticker
b.buy(100000, 0.1) # Buy the 0.1 BTC at the rate is 100,000 BTC/JPY
```

or

setting the enviromnet values base on `.env.sample`, and

```
require 'kaesen'
b =  Kaesen::Bitflyer.new
```

### Currently supported exchange markets to trade:

+ bitFlyer
+ BtcBox
+ coincheck
+ Zaif

### Currently supported exchange markets to get market information:

+ bitbank
+ bitFlyer Lightning
+ bitFlyer FX
+ BtcBox
+ coincheck
+ Kraken
+ LakeBTC
+ ~~MonetaGo~~ (deprecated)
+ Quoine
+ Zaif

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/him0/kaesen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Donation

bitcoin:1B1uB4Z4GoxejicoVs9c61S3jXx7BoHYDq
