require_relative 'spec_helper'
describe 'Rack::Defense::ban' do
  before do
    #
    # configure the Rack::Defense middleware with a ban
    # strategy.
    #
    Rack::Defense.setup do |config|
      # allow only given ips on path
      config.ban('allow_only_ip_list') do |req|
        req.path == '/protected' && !['192.168.0.1', '127.0.0.1'].include?(req.ip)
      end
    end
  end
  it 'ban matching requests' do
    check_request(:get, '/protected','192.168.0.2')
    check_request(:post, '/protected','192.168.0.3')
    check_request(:patch, '/protected','192.168.0.2')
    check_request(:delete, '/protected','192.168.0.2')
  end
  it 'allow non matching request' do
    check_request(:get, '/protected','192.168.0.1')
    check_request(:get, '/protected','127.0.0.1')
    check_request(:get, '/protectedx','192.168.0.5')
    check_request(:post, '/allowed','192.168.0.5')
  end

  def check_request(verb, path, ip)
    send verb, path, {}, 'REMOTE_ADDR' => ip
    expected_status = path == '/protected' && !['192.168.0.1', '127.0.0.1'].include?(ip) ?
      status_banned : status_ok
    assert_equal expected_status, last_response.status
  end
end

