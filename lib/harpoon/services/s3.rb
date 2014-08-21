require "aws-sdk"
require "uri"
require "public_suffix"

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
            #primary domain detected, let's make sure it exists
            bucket = setup_bucket(@config.domain["primary"])
            #setup bucket to server webpages
            @logger.info "Setting primary domain as website"
            bucket.configure_website
            #setup ACL
            @logger.info "Setting ACL"
            bucket.acl = :public_read


            history = setup_bucket(rollback_bucket(@config.domain["primary"]))
            @logger.info "Created rollback bucket"

            setup_dns_alias(@config.domain["primary"], bucket)


            if @config.domain["forwarded"]
              #we also want to forward some domains
              #make sure we have an array
              #TODO : Move all of this nonsense to the config object, it should be validating this stuff
              forwarded = @config.domain["forwarded"].is_a?(Array) ? @config.domain["forwarded"] : [@config.domain["forwarded"]]
              forwarded.each do |f|
                bucket = setup_bucket(f)
                @logger.info "Seting up redirect to primary"
                cw = AWS::S3::WebsiteConfiguration.new({redirect_all_requests_to: {host_name: @config.domain["primary"]}})
                bucket.website_configuration = cw
                setup_dns_alias(f, bucket)
              end
            end

            # print out DNS settings
            print_dns_settings(@config.domain["primary"])
          end
        end
      end

      def deploy
        
      end

      def list
        @logger.info "The following rollbacks are available:"
        if @config.domains && @config.domains["primary"]
          @logger.info @s3.buckets[rollback_bucket(@config.domains["primary"])].as_tree
        end
      end

      def doctor

      end

      def rollback

      end

      private

      def setup_dns_alias(domain, bucket)
        @logger.debug "Setup Domain Alias for #{domain}"
        #extract root domain
        rdomain = root_domain(domain)
        @logger.debug "Root Domain: #{rdomain}"
        #add that dot
        rdomain += "." unless rdomain.end_with?(".")
        domain += "." unless domain.end_with?(".")
        @logger.debug "Post Dot root: #{rdomain}"
        @logger.debug "Post Dot domain: #{domain}"


        #ensure we have a hosted zone
        hosted_zone = @r53.hosted_zones.find {|h| h.name == rdomain}
        hosted_zone = @r53.hosted_zones.create(rdomain, {comment: "Created By Harpoon"}) if !hosted_zone

        record = hosted_zone.rrsets[domain, "A"]

        dns_alias, zone_id = alias_and_zone_id(bucket.location_constraint)
        @logger.debug "Alias: #{dns_alias}, Zone: #{zone_id}"

        record = hosted_zone.rrsets.create(domain, "A", alias_target: {dns_name: dns_alias, hosted_zone_id: zone_id, evaluate_target_health: false}) unless record.exists?
        @logger.info "Created Host Record: #{record.name}, #{record.type}"
      end

      def setup_bucket(bucket_name)
        @logger.info "Creating bucket: #{bucket_name}"
        bucket = @s3.buckets[bucket_name]
        unless bucket.exists?
          bucket = @s3.buckets.create(bucket_name)
        end
        bucket
      end

      def root_domain(domain)
        #pull out the host if we have a full url
        domain = URI.parse(domain).host if domain.start_with?("http")
        PublicSuffix.parse(domain).domain
      end

      def alias_and_zone_id(constraint)
        #taken from: http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
        case constraint
        when "us-east-1"
          return "s3-website-us-east-1.amazonaws.com.", "Z3AQBSTGFYJSTF"
        when "us-west-2"
          return "s3-website-us-west-2.amazonaws.com.", "Z3BJ6K6RIION7M"
        when "us-west-1"
          return "s3-website-us-west-1.amazonaws.com.", "Z2F56UZL2M1ACD"
        when "eu-west-1"
          return "s3-website-eu-west-1.amazonaws.com.", "Z1BKCTXD74EZPE"
        when "ap-southeast-1"
          return "s3-website-ap-southeast-1.amazonaws.com.", "Z3O0J2DXBE1FTB"
        when "ap-southeast-2"
          return "s3-website-ap-southeast-2.amazonaws.com.", "Z1WCIGYICN2BYD"
        when "ap-northeast-1"
          return "s3-website-ap-northeast-1.amazonaws.com.", "Z2M4EHUR26P7ZW"
        when "sa-east-1"
          return "s3-website-sa-east-1.amazonaws.com.", "Z7KQH4QJS55SO"
        when "us-gov-west-1"
          return "s3-website-us-gov-west-1.amazonaws.com.", "Z31GFT0UA1I2HV"
        end
      end

      def print_dns_settings(domain)
        @logger.debug "Print DNS Settings for: #{domain}"
        rdomain = "#{root_domain(domain)}."
        @logger.debug "Root Domain: #{rdomain}"
        @logger.warn "=============================="
        @logger.warn "Please forward to the following DNS:"
        hosted_zone = @r53.hosted_zones.find {|h| h.name == rdomain}
        hosted_zone.rrsets[rdomain, "NS"].resource_records.each do |r|
          @logger.warn r[:value]
        end
        @logger.warn "=============================="
      end

      def rollback_bucket(domain)
        "#{domain}-history"
      end
    end
  end
end
