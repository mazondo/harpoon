require "aws-sdk"

module Harpoon
  module Services
    class S3
      def initialize(config, auth, logger)
        # Store what we're given for later
        @config = config
        @auth = auth
        @logger = logger

        # Ask for the users credentials
        @credentials = @auth.get_or_ask("s3", "Key", "Secret")

        if config.hosting_options && config.hosting_options["region"]
          region = config.hosting_options["region"]
        else
          region = "us-west-2"
        end

        AWS.config(access_key_id: @credentials[0], secret_access_key: @credentials[1], region: region)

        # setup amazon interfaces
        @s3 = AWS::S3.new
        @r53 = AWS::Route53.new
      end

      def setup
        if @config.domain
          #we have domain info, so let's make sure it's setup for it
          if @config.domain["primary"]
            @logger.info "Creating Primary domain: #{@config.domain["primary"]}"
            #primary domain detected, let's make sure it exists
            bucket = @s3.buckets[@config.domain["primary"]]
            unless bucket.exists?
              bucket = @s3.buckets.create(@config.domain["primary"])
            end
            #setup bucket to server webpages
            @logger.info "Setting primary domain as website"
            bucket.configure_website
            #setup ACL
            @logger.info "Setting ACL"
            bucket.acl = :public_read

            if @config.domain["forwarded"]
              #we also want to forward some domains
              #make sure we have an array
              #TODO : Move all of this nonsense to the config object, it should be validating this stuff
              forwarded = @config.domain["forwarded"].is_a?(Array) ? @config.domain["forwarded"] : [@config.domain["forwarded"]]
              forwarded.each do |f|
                @logger.info "Setting up forwarded domain: #{f}"
                bucket = @s3.buckets[f]
                unless bucket.exists?
                  bucket = @s3.buckets.create(f)
                end
                #setup redirects
                @logger.info "Seting up redirect to primary"
                bucket.configure_website do |c|
                  c.redirect_all_requests_to = {
                    host_name: @config.domain["primary"]
                  }
                end
              end
            end
          end
        end
      end

      def deploy

      end

      def list

      end

      def doctor

      end

      def rollback

      end
    end
  end
end
