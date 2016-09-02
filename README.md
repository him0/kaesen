# Kaesen (beta version)

A module of the united wrapper for exchanging Japanese yen and Bitcoin and collecting market information of any exchange markets that provide ordinary customers with API access.

## Installation

For each of your applications, add the following line to the application's Gemfile:

```ruby
gem 'kaesen', github: "him0/kaesen"
```

Then, run bundler:

    $ bundle install

## Usage

```
require 'kaesen'
b =  Kaesen::Bitflyer.new do |config|
  config.api_key = "XXX"
  config.api_secret = "YYY"
end
b.ticker
```

### Currently supported exchange markets to trade:

+ bitFlyer
+ BtcBox
+ coincheck
+ Zaif

### Currently supported exchange markets to get market information:

+ bitFlyer Lightning
+ bitFlyer FX
+ BtcBox
+ coincheck
+ Kraken
+ LakeBTC
+ MonetaGo
+ Quoine
+ Zaif

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/him0/kaesen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
