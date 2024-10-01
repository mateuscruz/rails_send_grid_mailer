# frozen_string_literal: true

require_relative 'adapter_mixin'

class SendGridMailer
  class TestAdapter
    include AdapterMixin

    def initialize(mail)
      @mail = mail
    end

    def deliver
      SendGridMailer.logger.info("SendGrid email sent: #{mail.to_json}")

      true
    end

    private

    attr_reader :mail
  end
end
