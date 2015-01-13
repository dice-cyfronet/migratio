require 'sidekiq'

module Migratio
  module Worker
    class Migrator
      include Sidekiq::Worker

      def perform(*params)
        begin
          perform_action(*params)
        rescue => e
          $stderr << "Something bad!\n"
          $stderr << "#{e}\n"
        end
      end

      protected

      def perform_action(*params)
        #by default do nothing
      end

      def config_file_path(name, type)
        File.join(config.configs_path, full_name(name, type))
      end

      def config
        @config ||= Migratio::Worker.config
      end
    end
  end
end

require_relative 'openstack_amazon_migrator'
require_relative 'openstack_openstack_migrator'
