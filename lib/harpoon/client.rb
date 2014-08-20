require 'fileutils'
require "thor"

module Harpoon
	class Client < Thor
		class_option :config, :type => :string

		desc "init", "Initializes a config file in current directory"
		def init
			#initialize a config file in the current directory
			begin
				Harpoon::Config.create(Dir.pwd)
			rescue Harpoon::Errors::AlreadyInitialized => e
				puts e.message
			else
				puts "Harpoon has been initialized"
			end
		end

		desc "deploy", "Deploys the current app"
		def deploy
			puts "DePLOY! #{options[:config]}"
		end
	end
end
