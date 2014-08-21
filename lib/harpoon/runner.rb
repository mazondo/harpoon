require "logger"
require "colorize"

module Harpoon
  class Runner
      def initialize(options)
        @logger = load_logger(options[:log_level])
        @config = Harpoon::Config.read(options[:config] || Dir.pwd, @logger)
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
          return Harpoon::Auth.new({namespace: @config.auth_namespace, logger: @logger})
        else
          return Harpoon::Auth.new({logger: @logger})
        end
      end

      def load_host
        if @config.hosting
          begin
            return Harpoon::Services.const_get(@config.hosting.capitalize).new(@config, @auth, @logger)
          rescue NameError => e
            raise Harpoon::Errors::InvalidConfiguration, "Unknown Hosting Service: #{@config.hosting}"
          end
        else
          raise Harpoon::Errors::InvalidConfiguration, "Hosting parameter is required"
        end
      end

      def load_logger(log_level = "info")
        log_level ||= "info"
        logger = Logger.new(STDOUT)

        #set log level
        case log_level.downcase
        when "debug"
          logger.level = Logger::DEBUG
        when "info"
          logger.level = Logger::INFO
        when "warn"
          logger.level = Logger::WARN
        when "error"
          logger.level = Logger::ERROR
        when "fatal"
          logger.level = Logger::FATAL
        end

        #set log formatter
        logger.formatter = proc do |severity, datetime, progname, msg|
          case severity.to_s.downcase
          when "debug"
            "DEBUG: #{msg}\n".colorize(:light_blue)
          when "info"
            "#{msg}\n".colorize(:gray)
          when "warn"
            "#{msg}\n".colorize(:yellow)
          when "error"
            "#{msg}\n".colorize(:orange)
          when "fatal"
            "#{msg}\n".colorize(:red)
          else
            "#{severity} - #{msg}\n"
          end
        end

        logger
      end
  end
end
