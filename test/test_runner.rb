require "helper"
describe "Runner" do
  before do
    @runner = Harpoon::Runner.new({config: "test/test_directory/test_client"})
    @runner.instance_eval {@service = load_host}
  end

  it "Should load the config from the config option" do
    assert_equal "test-app", @runner.instance_eval {@config.name}, "Should have loaded the config file"
  end

  it "Should have loaded the service from the config" do
    assert_equal Harpoon::Services::Test, @runner.instance_eval {@service.class}, "Should have set the service from the config file"
  end

  it "Should load the auth namespace from the service" do
    assert_equal "test-namespace", @runner.instance_eval {@auth.namespace}, "Should have set the namespace correctly"
  end

  it "Should pass any unknown commands to the service" do
    @runner.deploy
    assert_equal :deploy, @runner.instance_eval {@service.requests[0][0]}, "Should have run deploy on the service"
  end

  it "Should pass a default logger to everyone" do
    assert_equal Harpoon::Logger, @runner.instance_eval {@service.instance_eval {@logger.class}}, "Should have passed a logger to the service"
    assert_equal Harpoon::Logger, @runner.instance_eval {@auth.instance_eval {@logger.class}}, "Should have passed a logger to the auth"
    assert_equal Harpoon::Logger, @runner.instance_eval {@config.instance_eval {@logger.class}}, "Should have passed a logger to the config"
  end
end
