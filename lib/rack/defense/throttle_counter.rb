module Rack
  class Defense
    class ThrottleCounter

      KEY_PREFIX = 'rack-defense'

      attr_accessor :logger
      attr_accessor :name

      def initialize(name, max_requests, time_period, store)
        @name, @max_requests, @time_period = name.to_s, max_requests.to_i, time_period.to_i
        @store = store
      end

      def throttle?(key, timestamp=nil)
        timestamp ||= (Time.now.utc.to_f * 1000).to_i
        @store.eval SCRIPT,
          ["#{KEY_PREFIX}:#{@name}:#{key}"],
          [timestamp, @max_requests, @time_period]
      end

      SCRIPT = <<-LUA_SCRIPT
      local key = KEYS[1]
      local timestamp, max_requests, time_period = tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])
      if redis.call('rpush', key, timestamp) < max_requests then
        return false
      else
        return (timestamp - tonumber(redis.call('lpop', key))) <= time_period
      end
      LUA_SCRIPT

      private_constant :SCRIPT

    end
  end
end
