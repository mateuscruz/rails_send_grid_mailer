# frozen_string_literal: true

require_relative 'registry'

class SendGridMailer
  class Config
    include Singleton

    attr_accessor :api_key, :sender, :logger, :recipient_override, :subject_prefix,
                  :on_unsubscribe_group, :env_name
    attr_reader   :adapters, :templates, :unsubscribe_groups

    def initialize
      @logger               = Logger.new(STDOUT)
      @adapters             = Registry.new
      @templates            = Registry.new(strict: true)
      @unsubscribe_groups   = Registry.new(strict: true)
      @on_unsubscribe_group = proc { |_mail, _dynamic_template_data| }
    end
  end
end
