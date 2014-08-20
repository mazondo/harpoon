require "json"
require "fileutils"

module Harpoon
  class Config
    class << self

      def exists?(path)
        path = full_path(path, false)
        File.exists?(path)
      end

      def full_path(path, must_exist = true)
        path = File.expand_path(path)
        if File.directory?(path)
          path = File.join(path, "harpoon.json")
        end
        raise Harpoon::Errors::InvalidConfigLocation, "No config located at #{path}" if must_exist && !File.exists?(path)
        path
      end

      def create(path)
        path = full_path(path, false)
        if File.exists?(path)
          raise Harpoon::Errors::AlreadyInitialized, "Harpoon has already been initialized, see #{path}"
        end
        FileUtils.copy_file File.join(File.dirname(__FILE__), "templates", "harpoon.json"), path
      end

      def read(path = nil)
        path = full_path(path)
        if File.exists? path
          JSON.parse(IO.read(path))
        else
          raise Harpoon::Errors::InvalidConfigLocation, "Specified config doesn't exist, please create one"
        end
      end
    end
  end
end
