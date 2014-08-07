require 'sidekiq'

require_relative 'config'

module Migration
  module Worker
    def self.config
      @@config ||= Migration::Config.new @config_path
    end

    def self.config_path
      @@config_path = config_path
      @@config = nil
    end
  end
end
