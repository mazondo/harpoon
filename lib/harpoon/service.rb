module Harpoon
  # All services should include this module to work with Harpoon
  module Service

    #include all the class methods we need
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def auth(key, help = nil)
        required_auth.push({identifier: key, help: help})
      end

      def option(key, *args)
        args = args.last.is_a?(Hash) ? args.pop : {}

        default_options.send("#{key}=", args[:default]) if args[:default]
        default_options.requires(key) if args[:required]
      end

      # Defaults setup by the service
      # These are overridden by the hosting_options in the configuration
      # file if they exist
      def default_options
        @default_options ||= Harpoon::Config.new
      end

      # An array of required authentication params
      # These are provided to services as @auth[:key] values
      def required_auth
        @required_auth ||= []
      end
    end

    #instance methods
    def initialize(config, auth, logger)
      @logger = logger
      @auth = {}
      @options = self.class.default_options.dup

      @options.deep_merge!(config.hosting_options || {})

      @options.validate!

      if self.class.required_auth.length > 0
        req = self.class.required_auth.map {|h| h[:help]}
        auth_results = auth.__send__(:get_or_ask, config.hosting, *req)
        self.class.required_auth.each_with_index do |r, index|
          @auth[r[:identifier]] = auth_results[index]
        end
      end
    end
  end
end
