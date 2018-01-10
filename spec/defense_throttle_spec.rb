require_relative 'spec_helper'

describe 'Rack::Defense::throttle' do
  def window
    60 * 1000 # in milliseconds
  end

  before do
    @start_time = Time.utc(2015, 10, 30, 21, 0, 0)
    @user = {
      :name => "tester man",
      :max_requests => 5,
      :period => window
    }

    #
    # configure the Rack::Defense middleware with throttling
    # strategies.
    #
    Rack::Defense.setup do |config|
      # allow only 3 post requests on path '/login' per #window per ip
      config.throttle('login', 3, window) do |req|
        req.ip if req.path == '/login' && req.post?
      end

      # allow only 30 get requests on path '/search' per #window per ip
      config.throttle('res', 30, window) do |req|
        req.ip if req.path == '/search' && req.get?
      end

      # allow only 5 get requests on path /api/* per #window per authorization token
      config.throttle('api', 5, window) do |req|
        req.env['HTTP_AUTHORIZATION'] if %r{^/api/} =~ req.path
      end

      # get max_requests and period from a object in lambda
      max_requests = lambda{ |req| @user[:max_requests] }
      period = lambda{ |req| @user[:period] }
      
      config.throttle('api', max_requests, period) do |req|
        req.env['HTTP_AUTHORIZATION'] if %r{^/api/} =~ req.path
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
      50.times { |offset| check_get_request(offset + period*window) }
    end
  end
  it 'ban post requests higher than acceptable rate' do
    10.times do |period|
      7.times { |offset| check_post_request(offset + period*window) }
    end
  end
  it 'not have side effects between different throttle rules with mixed requests' do
    10.times do |period|
      50.times do |offset|
        check_get_request(offset + period*window)
        check_post_request(offset + period*window)
      end
    end
  end
  it 'not have side effects between request filtered by the same rule but with different keys' do
    10.times do |period|
      50.times do |offset|
        check_get_request(offset + period*window, ip='192.168.0.1')
        check_get_request(offset + period*window, ip='192.168.0.2')
      end
    end
  end
  it 'allow unfiltered requests' do
    50.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        # the rule matches the '/search' path and not '/searchx'
        get '/searchx', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal status_ok, last_response.status

        # the rule matches only get requests and not post
        post '/search', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal status_ok, last_response.status
      end
    end
    10.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        # the rule matches only post and not get
        get '/login', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal status_ok, last_response.status
      end
    end
  end
  it 'not have side effects between unfiltered and filtered requests' do
    50.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        get '/searchx', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal status_ok, last_response.status
        get '/search', {}, 'REMOTE_ADDR' => '192.168.0.1'
        assert_equal offset < 30 ? status_ok : status_throttled, last_response.status
      end
    end
  end
  it 'should work with key in http header' do
    10.times do |offset|
      check_request(:get, '/api/action', offset, 5,
        '192.168.0.1',
        'HTTP_AUTHORIZATION' => 'token api_token_here')
    end
  end

  def check_get_request(time_offset=0, ip='192.168.0.1', path='/search')
    check_request(:get, path, time_offset, 30, ip)
  end

  def check_post_request(time_offset=0, ip='192.168.0.1', path='/login')
    check_request(:post, path, time_offset, 3, ip)
  end

  def check_request(verb, path, time_offset, max_requests, ip, headers={})
    Timecop.freeze(@start_time + time_offset) do
      send verb, path, {}, headers.merge('REMOTE_ADDR' => ip)
      expected_status = (time_offset % window) >= max_requests ? status_throttled : status_ok
      assert_equal expected_status, last_response.status, "offset #{time_offset}"
    end
  end
end

