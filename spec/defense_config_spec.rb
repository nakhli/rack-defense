require_relative 'spec_helper'

describe Rack::Defense::Config do
  before do
    @config = Rack::Defense::Config.new
  end

  describe 'store' do
    it 'creates store instance from connection string' do
      url = 'redis://localhost:4444'
      @config.store = url
      assert url, conn_url(@config.store)
    end

    it 'update proxied store instance when store config changes' do
      obj1, obj2 = Redis.new(url: 'redis://localhost:3333'), Redis.new(url: 'redis://localhost:4444')

      @config.store = obj1
      assert conn_url(obj1), conn_url(@config.store)

      cached_store = @config.store

      @config.store = obj2
      assert conn_url(obj2), conn_url(@config.store)
      assert conn_url(obj2), conn_url(cached_store)
    end

    def conn_url(conn)
      "redis://#{conn.connection[:host]}:#{conn.connection[:port]}"
    end
  end
end
