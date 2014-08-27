module Harpoon
	require_relative "harpoon/auth"
	require_relative "harpoon/client"
	require_relative "harpoon/errors"
	require_relative "harpoon/config"
	require_relative "harpoon/runner"
	require_relative "harpoon/logger"

	# Services
	require_relative "harpoon/service"
	require_relative "harpoon/services/test"
	require_relative "harpoon/services/s3"
end
