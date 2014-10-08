require_relative 'spec_helper'

describe 'Rack::Defense::throttled?' do
  before do
    Timecop.safe_mode = true
    Redis.current.flushdb
    @start_time = Time.utc(2015, 10, 30, 21, 0, 0)

    #
    # configure the Rack::Defense middleware with two throttling
    # startegies.
    #
    Rack::Defense.setup do |config|
      # only 3 requests with a given path are allowed per minute and per ip
      config.throttle('login', 3, 60*1000) do |req|
        req.ip if req.path == '/login' && req.post?
      end

      # only 50 requests with a given path are allowed per minute and per ip
      config.throttle('res', 50, 60*1000) do |req|
        req.ip if req.path == '/search' && req.get?
      end
    end
  end
  it 'allow ok post' do
    check_post_request
  end
  it 'allow ok get' do
    check_get_request
  end
  it 'allow get requests with acceptable rate' do
    10.times do |period|
      50.times { |offset| check_get_request(offset + period*60*1000) }
    end
  end
  it 'ban get requests with high rate' do
    10.times do |period|
      100.times { |offset| check_get_request(offset + period*60*1000, offset>=50 ? 429 : 200) }
    end
  end
  it 'allow post requests with acceptable rate' do
    10.times do |period|
      3.times { |offset| check_post_request(offset + period*60*1000) }
    end
  end
  it 'ban post requests with high rate' do
    10.times do |period|
      7.times { |offset| check_post_request(offset + period*60*1000, offset>=3 ? 429 : 200) }
    end
  end

  def check_get_request(time_offset=0, expected_status=200, ip='192.168.169.112', path='/search')
    check_request(:get, path, time_offset, expected_status, ip)
  end

  def check_post_request(time_offset=0, expected_status=200, ip='192.168.169.112', path='/login')
    check_request(:post, path, time_offset, expected_status, ip)
  end

  def check_request(verb, path, time_offset=0, expected_status=200, ip='192.168.169.112')
    Timecop.freeze(@start_time + time_offset) do
      send verb, path, {}, 'REMOTE_ADDR' => ip
      assert_equal expected_status, last_response.status, "offset #{time_offset}"
    end
  end
end

