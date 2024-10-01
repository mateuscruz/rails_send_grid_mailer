# frozen_string_literal: true

require_relative 'adapter_mixin'
require_relative 'config/mixin'

class SendGridMailer
  class ApiAdapter
    include SendGrid
    include AdapterMixin
    include Config::Mixin

    def initialize(mail)
      @mail = mail
      @api  = SendGrid::API.new(api_key: api_key)
    end

    def deliver
      client.mail._('send').post(request_body: mail.to_json)

      logger.info("SendGrid template #{template_id} sent to #{recipients.join(',')}")

      true
    end

    private

    attr_reader :api, :mail

    def recipients
      mail.personalizations.flat_map do |personalization|
        personalization.dig('to').map { |to| to['email'] }
      end
    end

    def client
      api.client
    end

    def template_id
      mail.template_id
    end
  end
end
