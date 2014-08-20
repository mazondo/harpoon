require "helper"
describe "Client" do
  before do
    @client = Harpoon::Client.new
  end

  it "Should let me specify the config file" do
    args = ["deploy"]
    options = {
      config: "test/test_directory/test_client"
    }
    @client = Harpoon::Client.new(args, options)
    @client.invoke(:deploy, options)
  end
end
