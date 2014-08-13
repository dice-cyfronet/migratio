require_relative 'migrator'

module Migration
  module Worker
    class OpenstackOpenstackMigrator < Migrator

      def perform_action(image_uuid, compute_site)
        dir = File.dirname(__FILE__)
        `#{dir}/../../../scripts/openstack2openstack.sh #{image_uuid} #{dir}/../../../config/#{compute_site}.conf`
      end
    end
  end
end
