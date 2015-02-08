require "aws-sdk"
require "uri"
require "public_suffix"
require "pathname"

module Harpoon
  module Services
    class S3
      include Harpoon::Service

      auth :key, "Key"
      auth :secret, "Secret"

      option :region, default: "us-west-2"

      def setup
        if @options.primary_domain
          #primary domain detected, let's make sure it exists
          bucket = setup_bucket(@options.primary_domain)
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


          history = setup_bucket(rollback_bucket_name(@options.primary_domain))
          @logger.info "Created rollback bucket"

          setup_dns_alias(@options.primary_domain, bucket)


          if @options.forwarded_domain
            #we also want to forward some domains
            #make sure we have an array
            forwarded = @options.forwarded_domain.is_a?(Array) ? @options.forwarded_domain : [@options.forwarded_domain]
            forwarded.each do |f|
              bucket = setup_bucket(f)
              @logger.info "Seting up redirect to primary"
              cw = AWS::S3::WebsiteConfiguration.new({redirect_all_requests_to: {host_name: @options.primary_domain}})
              bucket.website_configuration = cw
              setup_dns_alias(f, bucket)
            end
          end

          # print out DNS settings
          print_dns_settings(@options.primary_domain)
        end
      end

      def deploy
        raise Harpoon::Errors::InvalidConfiguration, "Missing list of files" unless @options.files && @options.directory && @options.primary_domain
        if primary_bucket
          move_existing_to_history!
          @logger.info "Copying new release to s3"
          @options.files.each do |f|
            @logger.debug "Path: #{f}"
            relative_path = Pathname.new(f).relative_path_from(Pathname.new(@options.directory)).to_s
            @logger.debug "s3 key: #{relative_path}"
            primary_bucket.objects[relative_path].write(Pathname.new(f))
          end
          @logger.info "...done"
        else
          raise Harpoon::Errors::MissingSetup, "Required s3 buckets are not created.  Run harpoon doctor to test."
        end
      end

      def list
        @logger.info "The following rollbacks are available:"
        if rollback_bucket
          tree = rollback_bucket.as_tree
          rollbacks = tree.children.collect {|i| i.prefix.gsub(/\/$/, "").to_i }
          rollbacks.sort!.reverse!
          rollbacks.each_with_index do |r, index|
            @logger.info Time.at(r).strftime("#{index + 1} - %F %r")
          end
        else
          @logger.warn "Rollback bucket not yet created"
          @logger.suggest "Run harpoon setup to create one"
        end
      end

      def doctor
        @logger.pass "Region: #{@options.region}"
        # check configuration
        if @options.primary_domain
          @logger.pass "Primary Domain: #{@options.primary_domain}"
        else
          @logger.fail "Missing Primary Domain"
          exit
        end

        if @options.forwarded_domain
          @logger.pass "Forwarded Domains: #{@options.forwarded_domain}"
        else
          @logger.pass "No forwarded domains"
        end

        # check IAM permissions

        # check buckets exist and permissions
        primary_bucket = s3.buckets[@options.primary_domain]
        if primary_bucket.exists?
          @logger.pass "Primary bucket exists"
        else
          @logger.fail "Missing Primary domain bucket"
        end

        if @options.forwarded_domain
          forwarded = @options.forwarded_domain.is_a?(Array) ? @options.forwarded_domain : [@options.forwarded_domain]
          forwarded.each do |f|
            bucket = s3.buckets[f]
            if bucket.exists?
              @logger.pass "Forwarded bucket exists: #{f}"
              #check forwarding
              wc = bucket.website_configuration.to_hash
              @logger.debug "Website Configuration: #{wc}"
              if wc && wc[:redirect_all_requests_to] && wc[:redirect_all_requests_to][:host_name] == @options.primary_domain
                @logger.pass "Forwarding setup: #{f}"
              else
                @logger.fail "Forwarding needs to be setup: #{f}"
                @logger.suggest "Run `harpoon setup`"
              end
            else
              @logger.fail "Forwarded bucket doesn't exist: #{f}"
              @logger.suggest "Run `harpoon setup`"
            end
          end
        end

        # check domain setup


        # print DNS settings
        print_dns_settings(@options.primary_domain)
        @logger.info "...done"
      end

      def rollback(version)
        @logger.info "Not yet implemented!"
        @logger.info "Your rollbacks ARE safe on s3 #{rollback_bucket(@options.primary_domain)}"
        if rollback_bucket && primary_bucket
          @logger.debug "Rollback bucket found, ensuring version exists"
        else
          @logger.warn "Buckets not yet configured"
          @logger.suggest "Setup a primary domain in your configuration and run harpoon setup"
        end
      end

      private

      def s3
        @s3 ||= AWS::S3.new({access_key_id: @auth[:key], secret_access_key: @auth[:secret], region: @options.region})
      end

      def r53
        @r53 ||= AWS::Route53.new({access_key_id: @auth[:key], secret_access_key: @auth[:secret], region: @options.region})
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
        @logger.suggest "=============================="
        @logger.suggest "Please transfer domain to Amazon Nameservers:"
        hosted_zone = r53.hosted_zones.find {|h| h.name == rdomain}
        hosted_zone.rrsets[rdomain, "NS"].resource_records.each do |r|
          @logger.suggest r[:value]
        end
        @logger.suggest "=============================="
      end

      def move_existing_to_history!
        raise Harpoon::Errors::InvalidConfiguration, "Must have a primary domain defined" unless @options.primary_domain
        @logger.info "Moving existing deploy to history"
        current = s3.buckets[@options.primary_domain]
        history = s3.buckets[rollback_bucket(@options.primary_domain)]
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
        bucket.objects.delete_all
        @logger.debug "Files deleted"
      end

      def primary_bucket
        return @primary_bucket if defined? @primary_bucket
        if @options.primary_domain && s3.buckets[@options.primary_domain].exists?
          return @primary_bucket = s3.buckets[@options.primary_domain]
        else
          return false
        end
      end

      def rollback_bucket
        return @rollback_bucket if defined? @rollback_bucket
        if @options.primary_domain && s3.buckets[rollback_bucket_name(@options.primary_domain)].exists?
          return @rollback_bucket = s3.buckets[rollback_bucket_name(@options.primary_domain)]
        else
          return false
        end
      end

      def rollback_bucket_name(domain)
        "#{domain}-history"
      end
    end
  end
end
