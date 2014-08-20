require "helper"

describe "Test Hosting Module" do
	before do
		@hosting = Harpoon::Services::TestHosting.new
	end

	it "Should let me pass in an auth if required" do
		auth = Object.new
		host = Harpoon::Services::TestHosting.new({auth: auth})
		assert_equal auth, host.auth, "Should have let me pass in an auth"
	end

	it "Should let me upload files to a specific hosting location" do
		files = ["file1", "file2"]
		location = "www.kawmoon.com"
		response = @hosting.upload(location, files)
		assert response, "Should have gotten a response back"
	end

	it "Should let me specify that the uploaded data should be public" do
		files = ["file1", "file2"]
		location = "www.kawmoon.com"
		options = {"public" => true}
		response = @hosting.upload(location, files, options)
		assert @hosting.uploads[0][:options]["public"] == true, "Should have passed in the options param"
	end

	it "Should let me specific dns entries to add" do
		url = "www.kawmoon.com"
		response = @hosting.create_dns(url)
		assert @hosting.dns_changes[0], "Should have created a new dns record"
	end

	it "Should let me forward non-www to www" do
		from = "kawmoon.com"
		to = "www.kawmoon.com"
		response = @hosting.forward_dns(from, to)
		assert @hosting.dns_changes[0], "Shoud have changed dns"
	end
end
