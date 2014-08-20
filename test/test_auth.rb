require "helper"

describe "Auth token" do

	it "Should let me initialize a namespace" do
		auth = Harpoon::Auth.new
		assert_equal "main", auth.namespace, "Should default to main namespace"

		auth = Harpoon::Auth.new({namespace: "test"})
		assert_equal "test", auth.namespace, "Should have set the namespace"
	end

	it "should let me store and retrieve namespaced auth params" do
		auth = Harpoon::Auth.new({namespace: "test"})
		auth2 = Harpoon::Auth.new({namespace: "test2"})

		#delete if already exists
		auth.destroy "test-host"
		auth2.destroy "test-host"

		assert !auth.get("test-host"), "Should have destroyed values"
		assert !auth2.get("test-host"), "Should have destroyed values"

		auth.set "test-host", "key", "secret"
		auth2.set "test-host", "key2", "secret2"

		assert_equal ["key", "secret"], auth.get("test-host"), "Should have set Auth1"
		assert_equal ["key2", "secret2"], auth2.get("test-host"), "Should have set Auth2"
	end

	it "Should be able to handle single keys" do
		auth = Harpoon::Auth.new({namespace: "test"})

		# destroy if it exists
		auth.destroy "test-host"

		auth.set "test-host", "key"

		assert_equal ["key", nil], auth.get("test-host"), "Should have been able to handle a single key"
	end

	it "Should understand how to get or ask" do
		auth = Harpoon::Auth.new({namespace: "test"})
		auth.destroy "test-host"

		assert !auth.get("test-host"), "Should have destroyed values"

		auth.get_or_ask "test-host", "enter 1", "enter 2"

		assert_equal 1, auth.get("test-host")[0].to_i, "Should have stored it correctly"
		assert_equal 2, auth.get("test-host")[1].to_i, "Should have stored it correctly"
	end
end
