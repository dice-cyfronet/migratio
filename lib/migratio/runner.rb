require 'rubygems'
require 'sidekiq'

require_relative 'worker/openstack_amazon_migrator'
require_relative 'worker/openstack_openstack_migrator'
require_relative 'worker'

Sidekiq.configure_server do |config|
  config.redis = { namespace: Migratio::Worker.config.namespace, url:Migratio::Worker.config.redis_url }
end
