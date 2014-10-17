require 'rack'
require 'redis'
require 'delegate'

class Rack::Defense
  autoload :ThrottleCounter, 'rack/defense/throttle_counter'

  class Config
    BANNED_RESPONSE = ->(env) { [403, {'Content-Type' => 'text/plain'}, ["Forbidden\n"]] }
    THROTTLED_RESPONSE = ->(env) { [429, {'Content-Type' => 'text/plain'}, ["Retry later\n"]] }

    attr_accessor :banned_response
    attr_accessor :throttled_response

    attr_reader :bans
    attr_reader :throttles
    attr_reader :ban_callbacks
    attr_reader :throttle_callbacks

    def initialize
      self.banned_response = BANNED_RESPONSE
      self.throttled_response = THROTTLED_RESPONSE
      @throttles, @bans = {}, {}
      default_value = ->(h,k) { h[k]=[] }
      @ban_callbacks, @throttle_callbacks = Hash.new(&default_value), Hash.new(&default_value)
     end

    def throttle(rule_name, max_requests, period, &block)
      raise ArgumentError, 'rule name should not be nil' unless rule_name
      counter = ThrottleCounter.new(rule_name, max_requests, period, store)
      throttles[rule_name] = lambda do |req|
        key = block.call(req)
        key && counter.throttle?(key)
      end
    end

    def ban(rule_name, &block)
      raise ArgumentError, 'rule name should not be nil' unless rule_name
      bans[rule_name] = block
    end

    def after_ban(rule_name=nil, &block)
      ban_callbacks[rule_name] << block
    end

    def after_throttle(rule_name=nil, &block)
      throttle_callbacks[rule_name] << block
    end

    def store=(value)
      value = Redis.new(url: value) if value.is_a?(String)
      if @store
        @store.__setobj__(value)
      else
        @store = SimpleDelegator.new(value)
      end
    end

    def store
      # Redis.new uses REDIS_URL environment variable by default as URL.
      # See https://github.com/redis/redis-rb
      @store ||= SimpleDelegator.new(Redis.new)
    end
  end

  class << self
    attr_accessor :config

    def setup(&block)
      self.config = Config.new
      yield config
    end

    def ban?(req)
      matching_rule_name(config.bans, req)
    end

    def throttle?(req)
      matching_rule_name(config.throttles, req)
    end

    private

    def matching_rule_name(rules, req)
      entry = rules.find { |rule_name, filter| filter.call(req) }
      entry[0] if entry
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    klass, config = self.class, self.class.config
    req = ::Rack::Request.new(env)

    rule_name = klass.ban?(req)
    if rule_name
      invoke_callbacks(config.ban_callbacks, req, rule_name)
      return config.banned_response.call(env)
    end

    rule_name = klass.throttle?(req)
    if rule_name
      invoke_callbacks(config.throttle_callbacks, req, rule_name)
      return config.throttled_response.call(env)
    end

    @app.call(env)
  end

  private

  def invoke_callbacks(callbacks, req, rule_name)
    (callbacks[rule_name] || []).each { |callback| callback.call(req, rule_name) }
    (callbacks[nil] || []).each { |callback| callback.call(req, rule_name) }
  end
end
