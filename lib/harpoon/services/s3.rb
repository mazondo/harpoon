require "aws-sdk"
require "uri"
require "public_suffix"
require "pathname"

module Harpoon
  module Services
    class S3
      include Harpoon::Service

      # def initialize(config, auth, logger)
      #   # Store what we're given for later
      #   @config = config
      #   @auth = auth
      #   @logger = logger
      #
      #   # Ask for the users credentials
      #   @credentials = @auth.get_or_ask("s3", "Key", "Secret")
      #
      #   if config.hosting_options && config.hosting_options["region"]
      #     region = config.hosting_options["region"]
      #   else
      #     region = "us-west-2"
      #   end
      #
      #   AWS.config(access_key_id: @credentials[0], secret_access_key: @credentials[1], region: region)
      #
      #   # setup amazon interfaces
      #   s3 = AWS::S3.new
      #   r53 = AWS::Route53.new
      # end

      auth :key, "Key"
      auth :secret, "Secret"

      option :region, default: "us-west-2"

      def setup
        if @options["primary_domain"]
          #primary domain detected, let's make sure it exists
          bucket = setup_bucket(@config.domain["primary"])
          #setup bucket to server webpages
          @logger.info "Setting primary domain as website"
          bucket.configure_website
          #setup ACL
          @logger.info "Setting bucket policy"
          policy = AWS::S3::Policy.new
          policy.allow(
            actions: ['s3:GetObject'],
            resources: [bucket.objects],
            principals: :any
          )

          @logger.debug policy.to_json

          bucket.policy = policy


          history = setup_bucket(rollback_bucket(@config.domain["primary"]))
          @logger.info "Created rollback bucket"

          setup_dns_alias(@config.domain["primary"], bucket)


          if @options["forwarded_domain"]
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

      def deploy
        raise Harpoon::Errors::InvalidConfiguration, "Missing list of files" unless @config.files && @config.directory && @config.domain["primary"]
        move_existing_to_history!
        current_bucket = s3.buckets[@config.domain["primary"]]
        raise Harpoon::Errors::MissingSetup, "Required s3 buckets are not created, consider running harpoon setup first" unless current_bucket.exists?
        @logger.info "Writing files to s3"
        @config.files.each do |f|
          @logger.debug "Path: #{f}"
          relative_path = Pathname.new(f).relative_path_from(Pathname.new(@config.directory)).to_s
          @logger.debug "s3 key: #{relative_path}"
          current_bucket.objects[relative_path].write(Pathname.new(f))
        end
        @logger.info "Deploy complete"
      end

      def list
        @logger.info "The following rollbacks are available:"
        if @config.domain && @config.domain["primary"]
          tree = s3.buckets[rollback_bucket(@config.domain["primary"])].as_tree
          rollbacks = tree.children.collect {|i| i.prefix.gsub(/\/$/, "").to_i }
          rollbacks.sort!.reverse!
          rollbacks.each_with_index do |r, index|
            @logger.info Time.at(r).strftime("#{index + 1} - %F %r")
          end
        end
      end

      def doctor
        # check configuration
        if @config.domain
          if @config.domain["primary"]
            @logger.info "Primary Domain: #{@config.domain["primary"]}"
          else
            @logger.fatal "Missing Primary Domain"
            exit
          end
        else
          @logger.fatal "Missing Domain Configuration"
          exit
        end
        # check IAM permissions
        # check buckets exist
        primary_bucket = s3.buckets[@config.domain["primary"]]
        if primary_bucket.exists?
          @logger.info "Primary bucket exists"
        else
          @logger.fatal "Missing Primary domain bucket"
        end
        # check domain setup
        # print DNS settings
        print_dns_settings(@config.domain["primary"])
      end

      def rollback
        @logger.info "Not yet implemented!"
        @logger.info "But don't worry, your rollbacks are safely stored in #{rollback_bucket(@config.domain["primary"])}"
        self.list
      end

      private

      def s3
        @s3 ||= AWS::S3.new({access_key_id: @auth[:key], secret_access_key: @auth[:secret], region: @options[:region]})
      end

      def r53
        @r53 ||= AWS::Route53.new({access_key_id: @auth[:key], secret_access_key: @auth[:secret], region: @options[:region]})
      end

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
        hosted_zone = r53.hosted_zones.find {|h| h.name == rdomain}
        hosted_zone = r53.hosted_zones.create(rdomain, {comment: "Created By Harpoon"}) if !hosted_zone

        record = hosted_zone.rrsets[domain, "A"]

        dns_alias, zone_id = alias_and_zone_id(bucket.location_constraint)
        @logger.debug "Alias: #{dns_alias}, Zone: #{zone_id}"

        record = hosted_zone.rrsets.create(domain, "A", alias_target: {dns_name: dns_alias, hosted_zone_id: zone_id, evaluate_target_health: false}) unless record.exists?
        @logger.info "Created Host Record: #{record.name}, #{record.type}"
      end

      def setup_bucket(bucket_name)
        @logger.info "Creating bucket: #{bucket_name}"
        bucket = s3.buckets[bucket_name]
        unless bucket.exists?
          bucket = s3.buckets.create(bucket_name)
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
        hosted_zone = r53.hosted_zones.find {|h| h.name == rdomain}
        hosted_zone.rrsets[rdomain, "NS"].resource_records.each do |r|
          @logger.warn r[:value]
        end
        @logger.warn "=============================="
      end

      def rollback_bucket(domain)
        "#{domain}-history"
      end

      def move_existing_to_history!
        raise Harpoon::Errors::InvalidConfiguration, "Must have a primary domain defined" unless @config.domain["primary"]
        @logger.info "Moving existing deploy to history"
        current = s3.buckets[@config.domain["primary"]]
        history = s3.buckets[rollback_bucket(@config.domain["primary"])]
        raise Harpoon::Errors::MissingSetup, "The expected buckets are not yet created, please try running harpoon setup" unless current.exists? && history.exists?

        current_date = Time.now.to_i
        #iterate over current bucket objects and prefix them with timestamp, move to history bucket
        current.objects.each do |o|
          s3_key = File.join(current_date.to_s, o.key)
          @logger.debug "Original Key: #{o.key}"
          @logger.debug "History Key: #{s3_key}"
          @logger.debug "Metadata: #{o.metadata.to_h.inspect}"
          history.objects[s3_key].write(o.read, {metadata: o.metadata})
        end
        @logger.debug "Moved to history, deleting files from current bucket"
        #delete the current objects
        current.objects.delete_all
        @logger.debug "Files deleted"
      end
    end
  end
end
