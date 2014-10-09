require_relative 'spec_helper'

describe 'Rack::Defense::throttle' do
  STATUS_OK = 200
  STATUS_THROTTLED = 429
  PERIOD = 60 * 1000 # in milliseconds

  before do
    @start_time = Time.utc(2015, 10, 30, 21, 0, 0)

    #
    # configure the Rack::Defense middleware with two throttling
    # strategies.
    #
    Rack::Defense.setup do |config|
      # allow only 3 post requests on path '/login' per PERIOD per ip
      config.throttle('login', 3, PERIOD) do |req|
        req.ip if req.path == '/login' && req.post?
      end

      # allow only 50 get requests on path '/search' per PERIOD per ip
      config.throttle('res', 30, PERIOD) do |req|
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
  it 'ban get requests higher than acceptable rate' do
    10.times do |period|
      50.times { |offset| check_get_request(offset + period*PERIOD) }
    end
  end
  it 'ban post requests higher than acceptable rate' do
    10.times do |period|
      7.times { |offset| check_post_request(offset + period*PERIOD) }
    end
  end
  it 'not have side effects between differrent throttle rules with mixed requests' do
    10.times do |period|
      50.times do |offset|
        check_get_request(offset + period*PERIOD)
        check_post_request(offset + period*PERIOD)
      end
    end
  end
  it 'not have side effects between request filtered by the same rule but with different keys' do
    10.times do |period|
      50.times do |offset|
        check_get_request(offset + period*PERIOD, ip='192.168.0.1')
        check_get_request(offset + period*PERIOD, ip='192.168.0.2')
      end
    end
  end
  it 'allow unfiltered requests' do
    50.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        # the rule matches the '/search' path and not '/searchx'
        get '/searchx', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal STATUS_OK, last_response.status

        # the rule matches only get requests and not post
        post '/search', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal STATUS_OK, last_response.status
      end
    end
    10.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        # the rule matches only post and not get
        get '/login', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal STATUS_OK, last_response.status
      end
    end
  end
  it 'not have side effects between unfiltered and filtered requests' do
    50.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        get '/searchx', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal STATUS_OK, last_response.status
        get '/search', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal offset < 30 ? STATUS_OK : STATUS_THROTTLED, last_response.status
      end
    end
  end

  def check_get_request(time_offset=0, ip='192.168.0.1', path='/search')
    check_request(:get, path, time_offset, 30, ip)
  end

  def check_post_request(time_offset=0, ip='192.168.0.1', path='/login')
    check_request(:post, path, time_offset, 3, ip)
  end

  def check_request(verb, path, time_offset, max_requests, ip)
    Timecop.freeze(@start_time + time_offset) do
      send verb, path, {}, 'REMOTE_ADDR' => ip
      expected_status = (time_offset % PERIOD) >= max_requests ? STATUS_THROTTLED : STATUS_OK
      assert_equal expected_status, last_response.status, "offset #{time_offset}"
    end
  end
end

