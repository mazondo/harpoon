require 'helper'

describe "Client Tests" do

  before do
    @hosting = Harpoon::Services::TestHosting.new
    @client = Harpoon::Client.new({hosting: @hosting})
  end

  it "should let me pass in api keys" do
    client = Harpoon::Client.new({public_key: "asdf", private_key: "asdf2"})
    assert_equal "asdf", client.public_key, "Should have let me pass in a public key"
    assert_equal "asdf2", client.private_key, "Should have let me pass in a private key"
  end

  it "Should let me pass in the hosting library I want" do
    hosting = Object.new
    client = Harpoon::Client.new({hosting: hosting})
    assert_equal hosting, client.hosting, "Should have let me pass in the hosting I wanted"
  end

  it "Should be able to deploy without dns" do
    @client.deploy "testdeploy"
    assert @client.hosting.uploads[0], "Should have created an upload event"
  end

  it "Should be able to understand multiple to's" do
    @client.deploy "www.kawmoon.com,kawmoon.com", {dns: true}
    assert @client.hosting.uploads[0], "Should have uploaded something"
    assert @client.hosting.dns_changes.size == 2, "Should have implemented two DNS changes"
  end

end