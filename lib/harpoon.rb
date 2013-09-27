module Harpoon
	require_relative "harpoon/auth"
	require_relative "harpoon/client"

	# Services
	require_relative "harpoon/services/test_hosting.rb"
	require_relative "harpoon/services/aws_hosting.rb"
end