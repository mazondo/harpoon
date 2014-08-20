module Harpoon
	module Services
		class Test
			attr_accessor :options, :requests

			def initialize(options = {})
				@options = options
				@requests = []
			end

			def method_missing(method, *args)
				@requests.push [method, args]
			end
		end
	end
end
