module Harpoon
  module Services
    class BitBalloon
      include Harpoon::Service

      auth :key, "Client ID"
      auth :secret, "Client Secret"

      config :password, default: nil

      def setup
        #setup for future deploys
        bitballoon.sites.create(:name => @config[:name]) unless site
        site.update(custom_domain: @config[:primary_domain], password: @config[:password])
      end

      def deploy
        #deploy new code
      end

      def list
        #list available rollbacks
        site.deploys.each do |deploy, index|
          @logger.info "#{index} - #{deploy.created_at.strftime("%M/%D/%Y")}"
        end
      end

      def rollback(version)
        #rollback to {{version}}
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

        if @config[:primary_domain]
          if site.custom_domain == @config[:primary_domain]
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
        @bitballoon ||= BitBalloon::Client.new(:client_id => @auth[:key], :client_secret => @auth[:secret])
      end

      def site
        return @site if defined? @site
        bitballoon.sites.each do |s|
          return @site = s if s.name == @config[:name]
        end
        @logger.fatal "Site could not be found"
        @logger.suggest "Try running harpoon doctor"
      end
    end
  end
end
