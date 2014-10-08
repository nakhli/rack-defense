require 'rack'
require 'redis'

class Rack::Defense
  autoload :ThrottleCounter, 'rack/defense/throttle_counter'

  class Config
    attr_accessor :banned_response
    attr_accessor :throttled_response
    attr_reader :bans
    attr_reader :throttles

    def initialize
      @throttles, @bans = {}, {}
      self.banned_response = ->(env) { [403, {'Content-Type' => 'text/plain'}, ["Forbidden\n"]] }
      self.throttled_response = ->(env) { [429, {'Content-Type' => 'text/plain'}, ["Retry later\n"]] }
    end

    def throttle(name, max_requests, period, &block)
      counter = ThrottleCounter.new(name, max_requests, period, store)
      throttles[name] = lambda do |req|
        key = block[req]
        key && counter.throttle?(key)
      end
    end

    def ban(name, &block)
      bans[name] = block
    end

    def store=(value)
      @store = value.is_a?(String) ? Redis.new(url: value) : value
    end

    def store
      # Redis.new uses REDIS_URL environment variable by default as URL.
      # See https://github.com/redis/redis-rb
      @store ||= Redis.new
    end
  end

  class << self
    attr_accessor :config

    def setup(&block)
      self.config = Config.new
      yield config
    end

    def ban?(req)
      config.bans.any? { |name, filter| filter.call(req) }
    end

    def throttle?(req)
      config.throttles.any? { |name, filter| filter.call(req) }
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    klass, config = self.class, self.class.config
    req = ::Rack::Request.new(env)
    return config.banned_response[env] if klass.ban?(req)
    return config.throttled_response[env] if klass.throttle?(req)
    @app.call(env)
  end
end
