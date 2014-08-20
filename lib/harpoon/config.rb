require "json"
require "fileutils"

module Harpoon
  class Config
    # Checks if a config exists at a given path
    def self.exists?(path)
      path = full_path(path, false)
      File.exists?(path)
    end

    # Returns the full path of a config given a directory.
    # By default this raises an alert if the config doesn't exist.
    def self.full_path(path, must_exist = true)
      path = File.expand_path(path)
      if File.directory?(path)
        path = File.join(path, "harpoon.json")
      end
      raise Harpoon::Errors::InvalidConfigLocation, "No config located at #{path}" if must_exist && !File.exists?(path)
      path
    end

    # Create a config at a given path
    def self.create(path)
      path = full_path(path, false)
      if File.exists?(path)
        raise Harpoon::Errors::AlreadyInitialized, "Harpoon has already been initialized, see #{path}"
      end
      FileUtils.copy_file File.join(File.dirname(__FILE__), "templates", "harpoon.json"), path
    end

    # Load a config file from a given path
    # Returns a new config object
    def self.read(path = nil)
      path = full_path(path)
      if File.exists? path
        new JSON.parse(IO.read(path))
      else
        raise Harpoon::Errors::InvalidConfigLocation, "Specified config doesn't exist, please create one"
      end
    end

    # Initialize a new config object with the data loaded
    def initialize(data = {})
      @config = data
    end

    # Check for the configuration item
    def method_missing(method, *args)
      @config[method.to_s]
    end
  end
end
