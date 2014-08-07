# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'migration/worker/version'

Gem::Specification.new do |spec|
  spec.name          = 'migration-worker'
  spec.version       = Migration::Worker::VERSION
  spec.authors       = ['Paweł Suder']
  spec.email         = ['pawel@suder.info']
  spec.description   = %q{Migration worker}
  spec.summary       = %q{Worker is responsible for migrating virtual machine templates between sites}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
