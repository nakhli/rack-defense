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

      # get notified when requests get throttled
      config.after_throttle do |req, rules|
        @throttled << [req, rules]
      end

      # get notified when requests get banned
      config.after_ban do |req, rule|
        @banned << [req, rule]
      end
    end
  end
  it 'throttle rule gets called' do
    5.times do |offset|
      time = @start_time + offset
      Timecop.freeze(time) do
        post '/login', {}, 'REMOTE_ADDR' => '192.168.0.1'
        if offset < 3
          assert_equal status_ok, last_response.status
          assert_equal 0, @throttled.length
        else
          assert_equal status_throttled, last_response.status
          check_callback_data(@throttled, offset - 2, { 'login' => '192.168.0.1' }, '/login')
       end
      end
    end
  end
  it 'ban callback gets called' do
    5.times do |i|
      get '/forbidden'
      assert_equal status_banned, last_response.status
      check_callback_data(@banned, i + 1, 'forbidden', '/forbidden')
    end
  end

  def check_callback_data(trace, matching_request_count, rule_data, req_path)
    puts
    assert_equal matching_request_count, trace.length
    data = trace[-1]
    # check callback data
    assert_equal req_path, data[0].path
    assert_equal rule_data, data[1]
  end
end