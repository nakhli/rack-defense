require_relative 'spec_helper'

describe Rack::Defense::ThrottleCounter do
  before do
    @key = '192.168.0.1'
  end
  describe '.throttle?' do
    before { @counter = Rack::Defense::ThrottleCounter.new('upload_photo', 5, 10, Redis.current) }
    it 'allow request number max_requests if after period' do
      do_max_requests_minus_one
      refute @counter.throttle? @key, 11
    end
    it 'block request number max_requests if in period' do
      do_max_requests_minus_one
      assert @counter.throttle? @key, 10
    end
    it 'allow consecutive valid periods' do
      (0..20).each { |i| do_max_requests_minus_one(11 * i) }
    end
    it 'block consecutive invalid requests' do
      do_max_requests_minus_one
      (0..20).each { |i| assert @counter.throttle?(@key, 10 + i) }
    end
    it 'use a sliding window and not reset count after each full period' do
      [5, 6, 7, 8, 9].each { |t| refute @counter.throttle?(@key, t), "timestamp #{t}" }
      [12, 13, 14, 15].each { |t| assert @counter.throttle?(@key, t), "timestamp #{t}"}
    end
    it 'should unblock after blocking requests' do
      do_max_requests_minus_one
      assert @counter.throttle? @key, 10
      assert @counter.throttle? @key, 11
      refute @counter.throttle? @key, 16
    end
    it 'should include throttled(blocked) request into the request count' do
      [0, 1, 2, 3, 4].each { |t| refute @counter.throttle?(@key, t), "timestamp #{t}" }
      assert @counter.throttle? @key, 10
      [16, 17, 18, 19].each { |t| refute @counter.throttle?(@key, t), "timestamp #{t}" }
      assert @counter.throttle? @key, 20
    end
  end
  describe 'expire keys' do
    before do
      @redis = Redis.current
      @counter = Rack::Defense::ThrottleCounter.new('rule_name', 3, 10 * 1000, @redis)
      @throttle_key = "#{Rack::Defense::ThrottleCounter::KEY_PREFIX}:rule_name:#{@key}"
    end
    it 'expire throttle key' do
      start = Time.now.to_i

      3.times do
        refute @counter.throttle? @key
      end

      elapsed = Time.now.to_i - start
      if elapsed < 10
        assert @counter.throttle? @key
        assert @redis.exists @throttle_key
      else
        puts "Warning: test too slow elapsed:#{elapsed}s expected < #{10}"
      end

      # see http://redis.io/commands/expire
      # In Redis 2.4 the expire might not be pin-point accurate, and it could be between zero to one seconds out.
      # Since Redis 2.6 the expire error is from 0 to 1 milliseconds.
      sleep 10 + 0.001

      refute @redis.exists @throttle_key
    end
  end

  def do_max_requests_minus_one(offset=0)
    [0, 2, 3, 5, 9].map { |t| t + offset }.each do |t|
      refute @counter.throttle?(@key, t), "timestamp #{t}"
    end
  end
end
