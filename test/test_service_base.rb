require "helper"

#overwrite test service for this test
module Harpoon
  module Services
    class TestBase
      include Harpoon::Service
      attr_accessor :config, :requests

      auth :auth1, "Auth1"
      auth :auth2, "Auth2"

      option :default_option, default: true
      option :default_option_2, default: true
      option :default_option_required, required: true

      def method_missing(method, *args)
        @requests ||= []
        @requests.push [method, args]
      end
    end
  end
end

describe "Service Base" do
  before do
    @mock_auth = MiniTest::Mock.new
    @mock_logger = MiniTest::Mock.new
    d = {
      name: "test-app",
      hosting: :test,
      hosting_options: {default_option: "one", new_option: true, default_option_required: true}
    }
    @mock_options = Harpoon::Config.new(d)

    @mock_auth.expect :get_or_ask, ["asdf", "asdf2"], [Symbol, String, String]
  end

  it "Should request and verify authentication" do
    @service = Harpoon::Services::TestBase.new(@mock_options, @mock_auth, @mock_logger)
    @mock_auth.verify
    assert_equal "asdf", @service.instance_eval {@auth[:auth1]}, "Should have stored auth1 correctly"
    assert_equal "asdf2", @service.instance_eval {@auth[:auth2]}, "Should have stored auth2 correctly"
  end

  it "Should have merged in the hosting options with default values" do
    @service = Harpoon::Services::TestBase.new(@mock_options, @mock_auth, @mock_logger)
    assert_equal "one", @service.instance_eval {@options.default_option}
    assert_equal true, @service.instance_eval {@options.default_option_2}
    assert_equal true, @service.instance_eval {@options.new_option}
  end

  it "Should give us access to the root config object" do
    @service = Harpoon::Services::TestBase.new(@mock_options, @mock_auth, @mock_logger)
    assert_equal "test-app", @service.instance_eval {@config.name}
  end

  it "Should raise an error if required options aren't included" do
    @mock_options = Harpoon::Config.new({hosting: :test})
    assert_raises Harpoon::Errors::InvalidConfiguration do
      @service = Harpoon::Services::TestBase.new(@mock_options, @mock_auth, @mock_logger)
    end
  end
end
