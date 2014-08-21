require "helper"

describe "Config File" do

  it "Should raise an error for missing config" do
    assert_raises Harpoon::Errors::InvalidConfigLocation do
      config = Harpoon::Config.read("test_directory/missing.json")
    end
  end

  it "Should create a config where I tell it to" do
    temp_file = Harpoon::Config.full_path("test/test_directory/test_create", false)
    #does the temp file exist?  if so, delete it
    if Harpoon::Config.exists?(temp_file)
      File.delete(temp_file)
    end

    assert !File.exists?(temp_file), "Should have deleted old config"

    #create file
    Harpoon::Config.create(temp_file)

    assert File.exists?(temp_file), "Should have created config file"
    File.delete(temp_file)
  end

  it "Should know how to parse a config file" do
    config = Harpoon::Config.read("test/test_directory")
    assert_equal "Ryan", config.name, "Should have read the config file"
    assert_equal nil, config.other_value, "Should not have another value"
  end

  it "Should be able to tell me that a harpoon config exists" do
    assert Harpoon::Config::exists?("test/test_directory")
  end

  it "Should let me ask for the full path a config file" do
    assert_equal File.join(Dir.pwd, "test", "test_directory", "harpoon.json"), Harpoon::Config.full_path("test/test_directory"), "Should return the full file path of a config file"
  end

  it "Should be able to be given a logger" do
    config = Harpoon::Config.read("test/test_directory", Logger.new(STDOUT))
    assert_equal Logger, config.instance_eval {@logger.class}, "Should have stored the logger"
  end

  it "Should expect and sanitize input" do
    skip "Not implemented"
  end

  it "Should provide a list of files for the services" do
    nested = Harpoon::Config.read("test/test_directory/nested_files")
    unnested = Harpoon::Config.read("test/test_directory/unnested_files")

    assert_equal 1, nested.files.length, "Should have only found 1 file"
    assert_equal File.join(Dir.pwd, "test", "test_directory", "nested_files", "nested", "directory", "test3.txt"), nested.files.first, "Should have found the correct file"

    assert_equal 2, unnested.files.length, "Should have found 2 files"
    assert_equal [File.join(Dir.pwd, "test", "test_directory", "unnested_files", "nested", "test2.txt"), File.join(Dir.pwd, "test", "test_directory", "unnested_files", "test.txt")], unnested.files, "Should have found the right files"
  end
end
