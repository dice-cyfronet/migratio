require 'sidekiq'

module Migration
  module Worker
    class Migrator
      include Sidekiq::Worker

      def perform(*params)
        begin
          perform_action(*params)
        rescue Errno::EACCES => e
          $stderr << "Error: Cannot write to config files - continuing\n"
          $stderr << "#{e}\n"
        rescue Errno::ENOENT => e
          $stderr << "Error: Trying to remove non existing config files - continuing\n"
          $stderr << "#{e}\n"
        rescue Errno::ESRCH => e
          $stderr << "Warning: Nginx is dead - continuing\n"
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
        @config ||= Migration::Worker.config
      end
    end
  end
end

require_relative 'openstack_amazon_migrator'
require_relative 'openstack_openstack_migrator'
