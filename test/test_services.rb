require "helper"

describe "Test all services" do

	it "Should test all services to make sure they have the minimum" do
		skip "Not ready"
		#load all the services we know about and iterate over them, making sure they have the required
		# functions
		Harpoon::Services.constants.each do |c|
			m = Kernel.const_get("Harpoon").const_get("Services").const_get(c).instance_methods
			assert_includes m, :deploy, "Should include a deploy method"
			assert_includes m, :primary_domain, "Should include a primary domain method"
			assert_includes m, :foward_domain, "Should include a forward domain method"
			assert_includes m, :rollback, "Should include a rollback method"
			assert_includes m, :list, "Should include a list method"
		end
	end
end
