# frozen_string_literal: true

require_relative '../config'

class SendGridMailer
  class Config
    module Mixin
      def adapters
        config.adapters
      end

      def api_key
        config.api_key
      end

      def logger
        config.logger
      end

      def recipient_override
        config.recipient_override
      end

      def sender
        config.sender
      end

      def subject_prefix
        config.subject_prefix
      end

      def templates
        config.templates
      end

      def unsubscribe_groups
        config.unsubscribe_groups
      end

      def on_unsubscribe_group
        config.on_unsubscribe_group
      end

      def env_name
        config.env_name
      end

      def config
        Config.instance
      end
    end
  end
end
