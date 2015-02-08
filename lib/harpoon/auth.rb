require "netrc"
require 'fileutils'

module Harpoon
	class Auth
		attr_reader :namespace
		def initialize(options = {})
			@logger = options[:logger]
			if options[:namespace]
				@namespace = sanitize_namespace(options[:namespace])
			else
				@namespace = "main"
			end
		end

		def destroy(key)
			if netrc && netrc[netrc_key(key)]
				netrc.delete(netrc_key(key))
				netrc.save
			end
		end

		def set(key, value1 = nil, value2 = nil)
			FileUtils.mkdir_p(File.dirname(netrc_path))
			FileUtils.touch(netrc_path)
			unless running_on_windows?
				FileUtils.chmod(0600, netrc_path)
			end
			netrc[netrc_key(key)] = [netrc_nil(value1), netrc_nil(value2)]
			netrc.save
		end

		def get(key)
			if netrc
				n = netrc[netrc_key(key)]
				n ? n.map {|m| netrc_nil(m)} : n
			end
		end

		def get_or_ask(key, mes1 = nil, mes2 = nil)
			values = get(key)
			return values if values
			val1 = nil
			val2 = nil
			if mes1
				puts "Enter your #{mes1}:"
				val1 = $stdin.gets.to_s.strip
			end
			if mes2
				puts "Enter your #{mes2}:"
				val2 = $stdin.gets.to_s.strip
			end
			set(key, val1, val2)
			return [val1, val2]
		end

		private

		#netrc doesn't like nil values
		def netrc_nil(value = nil)
			if value && value != ""
				if value == "nothing-here"
					return nil
				else
					return value
				end
			else
				return "nothing-here"
			end
		end

		def netrc_key(key)
			"harpoon-#{@namespace}-#{key}"
		end

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

    def running_on_windows?
    		RUBY_PLATFORM =~ /mswin32|mingw32/
  	end

		def sanitize_namespace(n)
			n.gsub(/[^a-zA-Z0-9\-]/, "")
		end
	end
end
