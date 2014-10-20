require 'minitest/autorun'
require 'rack/test'
require 'redis'
require 'timecop'
require 'rack/defense'

class MiniTest::Spec
  include Rack::Test::Methods

  def status_ok; 200 end
  def status_throttled; 429 end
  def status_banned; 403 end

  def app
    Rack::Builder.new {
      use Rack::Defense
      run ->(_) { [200, {}, ['Hello World']] }
    }.to_app
  end

  before do
    Timecop.safe_mode = true
    keys = Redis.current.keys("#{Rack::Defense::ThrottleCounter::KEY_PREFIX}:*")
    Redis.current.del *keys if keys.any?
  end
end
