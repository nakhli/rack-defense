require 'rack'
require 'redis'
require 'delegate'

class Rack::Defense
  autoload :ThrottleCounter, 'rack/defense/throttle_counter'

  class Config
    BANNED_RESPONSE = ->(_) { [403, {'Content-Type' => 'text/plain'}, ["Forbidden\n"]] }
    THROTTLED_RESPONSE = ->(_) { [429, {'Content-Type' => 'text/plain'}, ["Retry later\n"]] }

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
      @ban_callbacks, @throttle_callbacks = [], []
     end

    def throttle(rule_name, max_requests, period, &block)
      raise ArgumentError, 'rule name should not be nil' unless rule_name
      counter = ThrottleCounter.new(rule_name, max_requests, period, store)
      throttles[rule_name] = lambda do |req|
        key = block.call(req)
        key if key && counter.throttle?(key)
      end
    end

    def ban(rule_name, &block)
      raise ArgumentError, 'rule name should not be nil' unless rule_name
      bans[rule_name] = block
    end

    def after_ban(&block)
      ban_callbacks << block
    end

    def after_throttle(&block)
      throttle_callbacks << block
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

    def setup
      self.config = Config.new
      yield config
    end

    def ban?(req)
      entry = config.bans.find { |_, filter| filter.call(req) }
      matching_rule = entry[0] if entry
      yield config.ban_callbacks, req, matching_rule if matching_rule && block_given?
      matching_rule
    end

    def throttle?(req)
      matching_rules = config.throttles.
          map { |rule_name, filter| [rule_name, filter.call(req)] }.
          select { |e| e[1] }.
          to_h
      yield config.throttle_callbacks, req, matching_rules if matching_rules.any? && block_given?
      matching_rules if matching_rules.any?
    end
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    klass, config = self.class, self.class.config
    req = ::Rack::Request.new(env)

    if klass.ban?(req, &method(:invoke_callbacks))
      config.banned_response.call(env)
    elsif klass.throttle?(req, &method(:invoke_callbacks))
      config.throttled_response.call(env)
    else
      @app.call(env)
    end
  end

  private

  def invoke_callbacks(callbacks, req, rule_data)
    callbacks.each do |callback|
      begin
        callback.call(req, rule_data)
      rescue
        # mute exception
      end
    end
  end
end
