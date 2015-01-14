require_relative 'migrator'

module Migratio
  module Worker
    class OpenstackAmazonMigrator < Migrator

      def perform_action(image_uuid, compute_site)
        dir = File.dirname(__FILE__)
        output = `#{dir}/../../../scripts/openstack2amazon-convert.sh "#{image_uuid}" "#{dir}/../../../config/#{compute_site}.conf"`
        Sidekiq::Client.push(
          'queue' => 'feedback',
          'class' => 'Atmosphere::UpdateMigrationJobStatusWorker',
          'args' => [image_uuid, config.name, compute_site, output])
        if $?.exitstatus == 1
          return
        end

        output = `#{dir}/../../../scripts/openstack2amazon-transfer.sh "#{image_uuid}" "#{dir}/../../../config/#{compute_site}.conf"`
        Sidekiq::Client.push(
          'queue' => 'feedback',
          'class' => 'Atmosphere::UpdateMigrationJobStatusWorker',
          'args' => [image_uuid, config.name, compute_site, output])
        if $?.exitstatus == 1
          return
        end

        output = `#{dir}/../../../scripts/openstack2amazon-import.sh "#{image_uuid}" "#{dir}/../../../config/#{compute_site}.conf"`
        Sidekiq::Client.push(
          'queue' => 'feedback',
          'class' => 'Atmosphere::UpdateMigrationJobStatusWorker',
          'args' => [image_uuid, config.name, compute_site, output])
        if $?.exitstatus == 1
          return
        end

        output = `#{dir}/../../../scripts/openstack2amazon-register.sh "#{image_uuid}" "#{dir}/../../../config/#{compute_site}.conf"`
        Sidekiq::Client.push(
          'queue' => 'feedback',
          'class' => 'Atmosphere::UpdateMigrationJobStatusWorker',
          'args' => [image_uuid, config.name, compute_site, output])
      end
    end
  end
end
