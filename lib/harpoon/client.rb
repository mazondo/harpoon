require 'fileutils'
module Harpoon
	class Client
		attr_accessor :private_key, :public_key
		attr_reader :hosting
		def initialize(options = {})
			self.private_key = options[:private_key]
			self.public_key = options[:public_key]
			@hosting = options[:hosting]
		end

		def init
			#initialize a config file in the current directory
			FileUtils.copy_file File.join(__FILE__, "templates", "harpoon.json"), File.join(Dir.pwd, "harpoon.json")
		end

		def deploy(to, options = {})
			# split the domains to see if we were given more than one
			to = to.split(",")
			primary = to.shift
			# grab all the files in the current directory that will be deployed
			files = Dir.glob(File.join(Dir.pwd, "**", "*"))
			response = self.hosting.upload(primary, files)
			if options[:dns]
				self.hosting.create_dns(primary)
				if to.size > 0
					to.each do |d|
						self.hosting.forward_dns(d, primary)
					end
				end
			end
		end
	end
end
