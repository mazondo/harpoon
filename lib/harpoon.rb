module Harpoon
	require_relative "harpoon/auth"
	require_relative "harpoon/client"
	require_relative "harpoon/errors"
	require_relative "harpoon/config"

	# Services
	require_relative "harpoon/services/test_hosting.rb"
	require_relative "harpoon/services/aws_hosting.rb"
end
