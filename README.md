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
# In config/initializers/rack-defense.rb
Rack::Defense.setup do |config|
  # your configuration here
end
```

## Throttling
The Rack::Defense middleware evaluates the throttling criterias (lambadas) against the incoming request. If the return value is falsy, the request is not throttled. Otherwise, the returned value is used as a key to throttle the request. The returned key could be the request IP, user name, API token or any discriminator to throttle the requests against.

### Examples

Throttle POST requests for path `/login` with a maximum rate of 3 request per minute per IP
```ruby
Rack::Defense.setup do |config|
  config.throttle('login', 3, 60 * 1000) do |req|
    req.ip if req.path == '/login' && req.post?
  end
end
```

Throttle GET requests for path `/image` with a maximum rate of 50 request per second per API token
```ruby
Rack::Defense.setup do |config|
  config.throttle('api', 50, 1000) do |req|
    req.env['HTTP_AUTHORIZATION'] if %r{^/api/} =~ req.path            
  end 
end
```
### Redis Configuration

Rack::Defense uses Redis to track request rates. By default, the `REDIS_URL` environment variable is used to setup the store. If not set, it falls back to host `127.0.0.1` port `6379`.
The redis store can be setup with either a connection url: 
```ruby
Rack::Defense.setup do |config|
  store = "redis://:p4ssw0rd@10.0.1.1:6380/15"
end
```
or directly with a connection object:
```ruby
Rack::Defense.setup do |config|
  store = Redis.new(host: "10.0.1.1", port: 6380, db: 15)
end
```

## Filtering

## License

Copyright [Sinbadsoft](http://www.sinbadsoft.com).

Licensed under the [MIT License](http://opensource.org/licenses/MIT).



