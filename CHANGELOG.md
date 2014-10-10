# 0.1.1
tag 0.1.1
* relax rack and redis gem required versions
* wrap redis connection with a proxy before intializing `ThrottleCounter` instances.
This avoids having to do the store intialization (`Config#sotre=`) -if any- before declaring 
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
* Throttle requests using a sliding window with period/max_request and request critera.
* Ban (block) requests matching critera.
* `Rack::Defense#setup` to configure redis store and throttled and banned responses
