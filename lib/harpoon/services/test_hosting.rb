module Harpoon
	module Services
		class TestHosting
			attr_accessor :uploads, :dns_changes
			attr_reader :auth
			def initialize(options = {})
				@auth = options[:auth]
				self.uploads = []
				self.dns_changes = []
			end

			def upload(location, files = [], options = {})
				self.uploads.push({location: location, files: files, options: options})
				return "Fake deploy successful"
			end

			def create_dns(url)
				self.dns_changes << {type: "create", info: method(__method__).parameters}
				return true
			end

			def forward_dns(from, to)
				self.dns_changes << {type: "forward", info: method(__method__).parameters}
				return true
			end
		end
	end
end