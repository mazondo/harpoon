require "bitballoon"
module Harpoon
  module Services
    class Bitballoon
      include Harpoon::Service

      auth :secret, "Access Token"

      def setup
        #setup for future deploys
        if site
          @logger.pass "Site already configured"
        else
          bitballoon.sites.create(:name => @config.name)
          @logger.pass "Site configured as #{@config.name}"
        end
        if @options.primary_domain
          site.update(custom_domain: @options.primary_domain)
          @logger.pass "Custom Domain configured"
        end
        @logger.suggest "You should run `harpoon doctor` to confirm setup"
      end

      def deploy
        #deploy new code
        if site
          if @config.directory
            @logger.info "Deploying #{@config.directory}"
            deploy = site.deploys.create(dir: @config.directory)
            site.wait_for_ready
            @logger.pass "Deployed."
          else
            @logger.fatal "We don't know what to deploy!"
          end
        else
          @logger.fatal "Uh oh, please run `harpoon doctor`"
        end
      end

      def list
        #list available rollbacks
        if site
          @logger.info "The following rollbacks are available"
          site.deploys.each_with_index do |deploy, index|
            @logger.info "#{index} - #{deploy.created_at}"
          end
          @logger.info "To Rollback, type `harpoon rollback {{deploy-number}}`"
        else
          @logger.fatal "Uh oh, please run `harpoon doctor`"
        end
      end

      def rollback(version)
        #rollback to {{version}}
        deploy = site.deploys.all[version.to_i]
        if deploy
          @logger.info "Publishing version #{deploy.id} created at #{deploy.created_at}"
          deploy.publish
          @logger.pass "Published."
        end
      end

      def doctor
        #check to see if we're ready for a deploy
        if site
          @logger.pass "Site configured with BitBalloon"
        else
          @logger.fail "Site not configured"
          @logger.suggest "Run `harpoon setup`"
          exit
        end

        if @options.primary_domain
          if site.custom_domain == @options.primary_domain
            @logger.pass "Custom domain configured"
          else
            @logger.fail "Custom domain not setup"
            @logger.suggest "Run `harpoon setup`"
            exit
          end
        end

        @logger.suggest "Make sure you have your DNS settings configured"
        @logger.suggest "Learn more at https://www.bitballoon.com/docs/custom_domains/"
      end

      private

      def bitballoon
        @bitballoon ||= ::BitBalloon::Client.new(:access_token => @auth[:secret])
      end

      def site
        return @site if defined? @site
        bitballoon.sites.each do |s|
          return @site = s if s.name == @config.name
        end
        @logger.fatal "Site could not be found"
        @logger.suggest "Try running `harpoon doctor`"
        return nil
      end
    end
  end
end
