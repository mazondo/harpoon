require "aws-sdk"
module Harpoon
	module Services
		class AwsHosting
			def initialize(options = {})
				@auth = options[:auth]
			end

			def upload(location, files = [], options = {})
				
			end

			def create_dns(url)
				
			end

			def forward_dns(from, to)
				
			end
		end
	end
end