module Harpoon
	module Services
		class Test
			include Harpoon::Service
			attr_accessor :config, :requests

			def initialize(config = nil, auth = nil, logger = nil)
				@config = config
				@auth = auth
				@logger = logger
			end

			def method_missing(method, *args)
				@requests ||= []
				@requests.push [method, args]
			end
		end
	end
end
