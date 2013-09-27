require "helper"

describe "Test all services" do

	it "Should test all services to make sure they have the minimum" do
		#load all the services we know about and iterate over them, making sure they have the required
		# functions
		Harpoon::Services.constants.each do |c|
			m = Kernel.const_get("Harpoon").const_get("Services").const_get(c).instance_methods
			assert_includes m, :upload, "Should include an upload method"
			assert_includes m, :forward_dns, "Should include a forward dns method"
			assert_includes m, :create_dns, "Should include a create dns method"
		end
	end
end