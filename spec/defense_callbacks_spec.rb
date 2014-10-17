require_relative 'spec_helper'

describe 'Rack::Defense::callbacks' do
  before do
    @start_time = Time.utc(2015, 10, 30, 21, 0, 0)
    @throttled = []
    @banned = []

    Rack::Defense.setup do |config|
      config.throttle('login', 3, 10 * 1000) do |req|
        req.ip if req.path == '/login' && req.post?
      end

      config.ban('forbidden') do |req|
         req.path == '/forbidden'
      end

      # get notified when a request gets throttled with the 'login' rule defined above
      config.after_throttle('login') do |req, name|
        @throttled << [:named, [req, name]]
      end

      # get notified when any request gets throttled
      config.after_throttle do |req, name|
        @throttled << [:global, [req, name]]
      end

      # this callback should never be called
      config.after_throttle('never') do |req, name|
        assert false
      end

     # get notified when a request gets banned with the 'forbidden' rule defined above
      config.after_ban('forbidden') do |req, name|
        @banned << [:named, [req, name]]
      end

      # get notified when any request gets banned
      config.after_ban do |req, name|
        @banned << [:global, [req, name]]
      end

      # this callback should never be called
      config.after_ban('never') do |req, name|
        assert false
      end
    end
  end
  it 'throttle named and global rules get called' do
    5.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        post '/login'
        if offset < 3
          assert_equal status_ok, last_response.status
          assert_equal 0, @throttled.length
        else
          assert_equal status_throttled, last_response.status
          check_callback_data(@throttled, offset-2, 'login', '/login')
       end
      end
    end
  end
  it 'ban named and global rules get called' do
    5.times do |i|
      get '/forbidden'
      assert_equal status_banned, last_response.status
      check_callback_data(@banned, i+1, 'forbidden', '/forbidden')
    end
  end

  def check_callback_data(trace, matching_request_count, rule_name, req_path)
    # only two callbacks should have been called: global and named
    assert_equal matching_request_count*2, trace.length
    data = trace[-2..-1].to_h
    # check callback data
    [:global, :named].each do |key|
      assert_equal req_path, data[key][0].path
      assert_equal rule_name, data[key][1]
    end
  end
end
