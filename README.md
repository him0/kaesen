# Kaesen

A module of the united wrapper for exchanging Japanese yen and Bitcoin and collecting market information of any exchange markets that provide ordinary customers with API access.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kaesen', github: "him0/kaesen"
```

And then execute:

    $ bundle install

## Usage

```
require 'kaesen'
b =  Kaesen::Bitflyer.new()
b.ticker
```

### Supported markets

+ Bitflyer
+ Btcbox
+ Coincheck
+ Zaif

### Markets Not Supported

+ LakeBTC
+ Kraken

## Development

This gem is beta version.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/him0/kaesen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
