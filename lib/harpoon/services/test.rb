module Harpoon
	module Services
		class Test
			attr_accessor :config, :requests

			def initialize(config = nil, auth = nil)
				@auth = auth
				@config = config
				@requests = []
			end

			def method_missing(method, *args)
				@requests.push [method, args]
			end
		end
	end
end
