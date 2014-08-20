module Harpoon
  class Runner
      def initialize(options)
        @config = Harpoon::Config.read(options[:config] || Dir.pwd)
        @auth = load_auth
        @service = load_host
      end

      def method_missing(method, *args)
        #don't know about this here, must be for the service
        @service.send(method, *args)
      end

      private

      def load_auth
        if @config.auth_namespace
          return Harpoon::Auth.new({namespace: @config.auth_namespace})
        else
          return Harpoon::Auth.new
        end
      end

      def load_host
        if @config.hosting
          begin
            return Harpoon::Services.const_get(@config.hosting.capitalize).new(@config, @auth)
          rescue NameError => e
            raise Harpoon::Errors::InvalidConfiguration, "Unknown Hosting Service: #{@config.hosting}"
          end
        else
          raise Harpoon::Errors::InvalidConfiguration, "Hosting parameter is required"
        end
      end
  end
end
