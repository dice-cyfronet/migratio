require_relative 'migrator'

module Migration
  module Worker
    class OpenstackAmazonMigrator < Migrator

      def perform_action(image_uuid, compute_site)
        dir = File.dirname(__FILE__)
        system("source #{dir}/config/#{compute_site}.conf; #{dir}/scripts/openstack2amazon.sh #{image_uuid}")
      end
    end
  end
end
