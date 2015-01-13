require_relative 'migrator'

module Migratio
  module Worker
    class OpenstackOpenstackMigrator < Migrator

      def perform_action(image_uuid, compute_site)
        dir = File.dirname(__FILE__)
        output = `#{dir}/../../../scripts/openstack2openstack-transfer.sh "#{image_uuid}" "#{dir}/../../../config/#{compute_site}.conf"`
        Sidekiq::Client.push(
          'queue' => 'feedback',
          'class' => 'UpdateMigrationJobStatusWorker',
          'args' => [image_uuid, config.name, compute_site, output])
        if $?.exitstatus == 1
          return
        end

        output = `#{dir}/../../../scripts/openstack2openstack-register.sh "#{image_uuid}" "#{dir}/../../../config/#{compute_site}.conf"`
        Sidekiq::Client.push(
          'queue' => 'feedback',
          'class' => 'UpdateMigrationJobStatusWorker',
          'args' => [image_uuid, config.name, compute_site, output])
      end
    end
  end
end
