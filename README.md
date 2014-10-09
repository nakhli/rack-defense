Rack::Defense
=============

A Rack middleware for throttling and filtering requests.

[![Code Climate](https://codeclimate.com/github/Sinbadsoft/rack-defense/badges/gpa.svg)](https://codeclimate.com/github/Sinbadsoft/rack-defense) [![Build Status](https://travis-ci.org/Sinbadsoft/rack-defense.svg)](https://travis-ci.org/Sinbadsoft/rack-defense)
[![Dependency Status](https://gemnasium.com/Sinbadsoft/rack-defense.svg)](https://gemnasium.com/Sinbadsoft/rack-defense)

Rack::Defense is a Rack middleware that allows you to easily add request rate limiting and request filtering to your Rack based application (Ruby On Rails, Sinatra etc.).

* Throttling (aka rate limiting) happens on __sliding window__ using the provided period, request criteria and maximum request number. It uses Redis to track the request rate.

* Request filtering allows to reject requests based on provided critera.

Rack::Defense has a small footprint and only two dependencies: [rack](https://github.com/rack/rack) and [redis](https://github.com/redis/redis-rb).

## Getting started

Install the rack-defense gem; or add it to you Gemfile with bundler:

```ruby
# In your Gemfile
gem 'rack-defense'
```
Tell your app to use the Rack::Defense middleware. For Rails 3+ apps:
```
# In config/application.rb
config.middleware.use Rack::Defense
```

Or for Rackup files:
```
# In config.ru
use Rack::Defense
```

Add a `rack-defense.rb` file to `config/initalizers/`:

```ruby
# In config/initializers/rack-attack.rb
Rack::Defense.setup do |config|
  # your configuration here
end
```

## Throttling

## Filtering

## License

Copyright [Sinbadsoft](http://www.sinbadsoft.com).

Licensed under the [MIT License](http://opensource.org/licenses/MIT).



