require_relative 'spec_helper'

describe 'Rack::Defense::throttle_expire_keys' do
  def window
    10 * 1000 # in milliseconds
  end

  before do
    Rack::Defense.setup do |config|
      # allow 1 requests per #window per ip
      config.throttle('rule', 3, window) { |req| req.ip if req.path == '/path' }
    end
  end

  it 'expire throttle key' do
    ip = '192.168.169.244'
    throttle_key = "#{Rack::Defense::ThrottleCounter::KEY_PREFIX}:rule:#{ip}"
    redis = Rack::Defense.config.store
    start = Time.now.to_i
    3.times do
      get '/path', {}, 'REMOTE_ADDR' => ip
      assert status_ok, last_response.status
    end

    get '/path', {}, 'REMOTE_ADDR' => ip
    elapsed = Time.now.to_i - start
    if elapsed < window
      assert status_throttled, last_response.status
      assert redis.exists throttle_key
    else
      puts "Warning: test too slow elapsed:#{elapsed}s expected < #{window}"
    end

    # Since Redis 2.6 the expire error is from 0 to 1 milliseconds. See http://redis.io/commands/expire
    sleep (window / 1000) + 0.002

    refute redis.exists throttle_key
  end
end