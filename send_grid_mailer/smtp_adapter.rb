# frozen_string_literal: true

require 'ruby-handlebars'
require_relative 'adapter_mixin'
require_relative 'config/mixin'

class SendGridMailer
  class SMTPAdapter
    include SendGrid
    include AdapterMixin
    include Config::Mixin

    def initialize(mail)
      @mail = mail
      @api  = SendGrid::API.new(api_key: api_key)
    end

    def deliver
      ApplicationMailer.send_inline_email(
        from: from,
        to: recipients,
        subject: subject,
        attachments: attachments,
        body: body
      ).deliver
    end

    private

    attr_reader :api, :mail

    def attachments
      mail.attachments.each_with_object({}) do |attachment, attachments|
        attachments[attachment['filename']] = Base64.strict_decode64(attachment['content'])
      end
    end

    def body
      body_node_placeholder            = send_grid_layout.xpath('//td[contains(text(), "<% body %>")]').first
      body_node_placeholder.inner_html = parsed_template

      send_grid_layout.to_html
    end

    def send_grid_layout
      @send_grid_layout ||= begin
        response = client.mail_settings.template.get()

        Nokogiri::HTML(JSON(response.body)['html_content'])
      end
    end

    def subject
      Handlebars::Handlebars
        .new
        .compile(send_grid_template[:subject])
        .call(subject: dynamic_template_data[:subject])
    end

    def parsed_template
      Handlebars::Handlebars
        .new
        .compile(send_grid_template[:html_content])
        .call(dynamic_template_data)
    end

    def send_grid_template
      @send_grid_template ||= begin
        response = client.templates._(template_id).get
        body     = JSON(response.body)

        body['versions'].find { |version| version['active'].positive? }.with_indifferent_access
      end
    end

    def from
      name, email = mail.from.values_at('name', 'email')

      name.present? ? "#{name} <#{email}>" : email
    end

    def recipients
      personalizations.flat_map do |personalization|
        personalization.dig('to').map { |to| to['email'] }
      end
    end

    def dynamic_template_data
      personalizations.map { |personalization| personalization['dynamic_template_data'] }.first.with_indifferent_access
    end

    def personalizations
      mail.personalizations
    end

    def client
      api.client
    end

    def template_id
      mail.template_id
    end
  end
end
