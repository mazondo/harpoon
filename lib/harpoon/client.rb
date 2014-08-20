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
			runner = Harpoon::Runner.new(options)
			runner.deploy
		end

		desc "doctor", "Check the health of the current deploy strategy"
		def doctor
			runner = Harpoon::Runner.new(options)
			runner.doctor
		end

		desc "list", "List available rollbacks"
		def list
			runner = Harpoon::Runner.new(options)
			runner.list
		end

		desc "rollback", "Rollback to previous release"
		def rollback
			runner = Harpoon::Runner.new(options)
			runner.rollback
		end
	end
end
