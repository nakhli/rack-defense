require_relative 'spec_helper'

describe Rack::Defense::ThrottleCounter do
  before do
    Redis.current.flushdb
    @counter = Rack::Defense::ThrottleCounter.new('upload_photo', 5, 10, Redis.current)
    @key = '127.0.0.1'
  end

  describe '.throttle?' do
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
      [6, 7, 8, 9].each { |t| refute @counter.throttle?(@key, t), "timestamp #{t}" }
      [12, 13, 14].each { |t| assert @counter.throttle?(@key, t), "timestamp #{t}"}
    end
    it 'should unblock after blocking requests' do
      do_max_requests_minus_one
      assert @counter.throttle? @key, 10
      assert @counter.throttle? @key, 11
      refute @counter.throttle? @key, 16
    end
    it 'should include throttled(blocked) request into the request count' do
      [0, 1, 2, 3].each { |t| refute @counter.throttle?(@key, t), "timestamp #{t}" }
      assert @counter.throttle? @key, 10
      [17, 18, 19].each { |t| refute @counter.throttle?(@key, t), "timestamp #{t}" }
      assert @counter.throttle? @key, 20
    end
  end

  def do_max_requests_minus_one(offset=0)
    [0, 3, 5, 9].map { |t| t + offset }.each do |t|
      refute @counter.throttle?(@key, t), "timestamp #{t}"
    end
  end
end
