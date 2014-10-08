require 'minitest/autorun'
require 'rack/test'
require 'rack/defense'
require 'redis'
require 'timecop'

class MiniTest::Spec
  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      use Rack::Defense
      run ->(env) { [200, {}, ['Hello World']] }
    }.to_app
  end
end
