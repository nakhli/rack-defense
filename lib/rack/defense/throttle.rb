module Rack
  class Defense
    class Throttle

      KEY_PREFIX = 'rack-defense'

      attr_accessor :logger
      attr_accessor :name

      def initialize(name, max_hits, time_period, store)
        @name, @max_hits, @time_period = name.to_s, max_hits.to_i, time_period.to_i
        @key = "#{KEY_PREFIX}:#{@name}"
        @store = store
      end

      def throttle?(timestamp=nil)
        timestamp ||= (Time.now.utc.to_f * 1000).to_i
        @store.eval SCRIPT, [@key], [timestamp, @max_hits, @time_period]
      end

      SCRIPT = <<-LUA_SCRIPT
      local key = KEYS[1]
      local timestamp, max_hits, time_period = tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3])
      local length = redis.call('rpush', key, timestamp)
      if length < max_hits then
        return false
      else
        return (timestamp - tonumber(redis.call('lpop', key))) <= time_period
      end
      LUA_SCRIPT

      private_constant :SCRIPT

    end
  end
end
