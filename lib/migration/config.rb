require 'yaml'

ROOT_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))

module Migration
  class Config
    def initialize(path=nil)
      config_path = path || default_config_path

      if File.exists?(config_path)
        @config = YAML.load_file(config_path)
      else
        @config = {}
      end
    end

    def queues
      @config['queues'] || ['default']
    end

    def redis_url
      @config['redis_url'] || 'redis://localhost:6379'
    end

    def namespace
      @config['namespace'] || 'air'
    end

    def default_config_path
      File.join(ROOT_PATH, 'config.yml')
    end
  end
end
