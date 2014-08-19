require "netrc"
require 'fileutils'

module Harpoon
	class Auth
		class << self

			attr_accessor :api_key

			def netrc_path
		      default = Netrc.default_path
		      encrypted = default + ".gpg"
		      if File.exists?(encrypted)
		        encrypted
		      else
		        default
		      end
		    end

		    def netrc
		      @netrc ||= begin
		        File.exists?(netrc_path) && Netrc.read(netrc_path)
		      rescue => error
		        if error.message =~ /^Permission bits for/
		          perm = File.stat(netrc_path).mode & 0777
		          abort("Permissions #{perm} for '#{netrc_path}' are too open. You should run `chmod 0600 #{netrc_path}` so that your credentials are NOT accessible by others.")
		        else
		          raise error
		        end
		      end
		    end

		    def read_credentials
		 		 # read netrc credentials if they exist
		        if netrc
		         @credentials = netrc["harpoon"] == nil ? ask_for_and_save_credentials : netrc["harpoon"]
		        end
		    end

		    def write_credentials(priv, pub)
		    	FileUtils.mkdir_p(File.dirname(netrc_path))
		    	FileUtils.touch(netrc_path)
		    	unless running_on_windows?
		    		FileUtils.chmod(0600, netrc_path)
		    	end
		    	netrc["harpoon"] = [priv, pub]
		    	netrc.save
		    end

		    def delete_credentials
		    	@credentials = nil
		    	if netrc
		    		netrc.delete("harpoon")
		    		netrc.save
		    	end
		    end

		    def credentials
		    	@credentials || ask_for_and_save_credentials
		    end

		    def ask_for_and_save_credentials
		    	puts "Enter your Private Key:"
		    	private_key = $stdin.gets.to_s.strip
		    	puts "Enter your Public Key"
		    	public_key = $stdin.gets.to_s.strip
		    	write_credentials(private_key, public_key)
		    	return [private_key, public_key]
		    end

		    def running_on_windows?
	      		RUBY_PLATFORM =~ /mswin32|mingw32/
	    	end
		end
	end
end
