# frozen_string_literal: true

require File.expand_path(
  File.join('..', 'lib', 'omniauth', 'wild_apricot', 'version'),
  __FILE__
)

Gem::Specification.new do |gem|
  gem.name          = 'omniauth-wild-apricot'
  gem.version       = OmniAuth::WildApricot::VERSION
  gem.license       = 'MIT'
  gem.summary       = %(A WildApricot OAuth2 strategy for OmniAuth 1.x)
  gem.description   = %(A WildApricot OAuth2 strategy for OmniAuth 1.x. This allows you to login to WildApricot with your ruby app.)
  gem.authors       = ['Fred Zirdung']
  gem.email         = ['fred@rocket-house.com']
  gem.homepage      = 'https://github.com/rocket-house/omniauth-wild-apricot'

  gem.files         = `git ls-files`.split("\n")
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.2'

  gem.add_runtime_dependency 'oauth2', '~> 2.0'
  gem.add_runtime_dependency 'omniauth', '~> 2.0'
  gem.add_runtime_dependency 'omniauth-oauth2', '~> 1.8'

  gem.add_development_dependency 'rake', '~> 12.0'
  gem.add_development_dependency 'rspec', '~> 3.6'
end
