require "helper"

describe "Test Hosting Module" do
	before do
		@hosting = Harpoon::Services::Test.new
	end

	it "Should let me make requests" do
		@hosting.deploy "options", "go", "here"
		assert_equal :deploy, @hosting.requests[0][0]
		assert_equal ["options", "go", "here"], @hosting.requests[0][1]
	end
	
end
