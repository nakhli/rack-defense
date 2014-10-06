require 'rack'
require 'redis'

class Rack::Defense

  autoload :Throttle, 'rack/defense/throttle'

  private

  def store
    # Redis.new uses REDIS_URL environment variable by default URL.
    # See https://github.com/redis/redis-rb
    @store ||= Redis.new
  end
end
