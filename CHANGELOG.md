# 0.2.1
tag 0.2.1

* Added auto-expiration of redis throttle keys using the redis command [PEXPIRE](http://redis.io/commands/pexpire).
A throttle keys is therefore automatically cleaned up if no activity is recorded against it for more than the specified
throttle period.

# 0.2.0
tag 0.2.0

* Added notifications for throttle and ban events. Callbacks are registered with `Config#after_ban` and
`Config#after_throttle` methods.

# 0.1.1
tag 0.1.1

* Relax rack and redis gem required versions
* Wrap redis connection with a proxy before initializing `ThrottleCounter` instances.
This avoids having to do the store initialization (`Config#sotre=`) -if any- before declaring
throttle rules (`Config#throttle`). For instance, the following configuration is now correct:

```ruby
Rack::Defense.setup do |config|
  config.throttle('name', 100, 1000) { |req| req.ip if req.path='/path' }

  # no need to set the store before the throttle rule. it can be done at any moment in config section
  config.store = 'redis://server:3333/0'
end
```

# 0.1.0
tag 0.1.0

* Throttle requests using a sliding window with period/max_request and request criteria.
* Ban (block) requests matching criteria.
* `Rack::Defense#setup` to configure redis store and throttled and banned responses
