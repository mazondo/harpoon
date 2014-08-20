module Harpoon
	module Services
		class Test
			attr_accessor :config, :requests

			def initialize(config = nil, auth = nil, logger = nil)
				@auth = auth
				@config = config
				@requests = []
				@logger = logger
			end

			def method_missing(method, *args)
				@requests.push [method, args]
			end
		end
	end
end
