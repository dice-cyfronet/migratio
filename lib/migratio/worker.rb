require 'sidekiq'

require_relative 'config'

module Migratio
  module Worker
    def self.config
      @@config ||= Migratio::Config.new @config_path
    end

    def self.config_path
      @@config_path = config_path
      @@config = nil
    end
  end
end
