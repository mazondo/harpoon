require "helper"

describe "Logger" do
  before do
    @logger = Harpoon::Logger.new(STDOUT)
  end

  it "Should understand how to record a pass" do
    assert defined?(@logger.pass), "Should have a pass method"
  end

  it "Should understand how to record a fail" do
    assert defined?(@logger.fail), "Should have a fail method"
  end

  it "Should understand how to record a suggestion" do
    assert defined?(@logger.suggest), "Should have a suggest method"
  end
end
