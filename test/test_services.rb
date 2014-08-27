require "helper"

describe "Test all services" do

	it "Should test all services to make sure they have the minimum" do
		#load all the services we know about and iterate over them, making sure they have the required
		# functions
		Harpoon::Services.constants.each do |c|
			next if c.to_s == "Test" #skip the test
			next if c.to_s == "TestBase" #skip base test
			m = Kernel.const_get("Harpoon").const_get("Services").const_get(c).instance_methods
			assert_includes m, :deploy, "Should include a deploy method"
			assert_includes m, :doctor, "Should include a doctor method"
			assert_includes m, :rollback, "Should include a rollback method"
			assert_includes m, :list, "Should include a list method"
		end
	end
end
