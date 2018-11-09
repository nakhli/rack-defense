# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rack/defense/version'

Gem::Specification.new do |s|
  s.name = 'rack-defense'
  s.version = Rack::Defense::VERSION
  s.license = 'MIT'

  s.authors = ['Chaker Nakhli']
  s.email = ['chaker.nakhli@gmail.com']

  s.files = Dir.glob('{bin,lib}/**/*') + %w(Rakefile README.md)
  s.test_files = Dir.glob('spec/**/*')
  s.homepage = 'http://github.com/nakhli/rack-defense'
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.summary = 'Throttle and filter requests'
  s.description = 'A rack middleware for throttling and filtering requests'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency 'rack', '>= 1.3', '<= 2.1'
  s.add_dependency 'redis', '~> 4'
  s.add_development_dependency 'rake', '~> 10.3'
  s.add_development_dependency 'minitest', '~> 5.4'
  s.add_development_dependency 'rack-test', '~> 0.6'
  s.add_development_dependency 'timecop', '~> 0.7'
end
