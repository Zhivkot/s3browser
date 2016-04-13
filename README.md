# S3Browser

The S3Browser is a simple wrapper around Amazon's [S3 Service](https://aws.amazon.com/s3/).
Apart from listing files and managing, S3 doesn't give you a lot of functionality.

This wrapper gives you two killer functions:

* [x] Search
* [x] Sorting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 's3browser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3browser

## Usage

Here's an example config.ru for booting S3Browser::Server in your choice of Rack server:

```ruby
# config.ru
require 's3browser/server'
run S3Browser::Server
```

You can mount S3Browser to existing Rack (Sinatra) application as well:

```ruby
# config.ru
require 'your_app'

require 's3browser/server'
run Rack::URLMap.new('/' => Sinatra::Application, '/s3browser' => S3Browser::Server)
```

Run the fetcher

```bash
bundle exec rake fetch
```

Run the server

```bash
bundle exec rake server
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jrgns/s3browser.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

