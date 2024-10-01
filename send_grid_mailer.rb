# frozen_string_literal: true

require 'sendgrid-ruby'
require_relative 'send_grid_mailer/config/mixin'

class SendGridMailer
  extend  Config::Mixin
  include Config::Mixin
  include SendGrid

  def initialize
    @send_grid_mail = SendGrid::Mail.new
    @attachments    = Hash.new
  end

  def self.method_missing(name, *infinite_args, **keyword_args, &block)
    return super(name, *infinite_args, **keyword_args, &block) unless instance_methods.include?(name)

    new.public_send(name, *infinite_args, **keyword_args, &block)
  end

  def self.respond_to_missing?(method_name, _include_private = false)
    instance_methods.include?(method_name)
  end

  def self.configure
    yield(config)
  end

  protected

  attr_reader :attachments

  def mail(subject: fallback_i18n_subject, to:, data:, template_id: default_template_id, unsubscribe_group: nil)
    send_grid_mail.from        = SendGrid::Email.new(email: sender)
    send_grid_mail.template_id = template_id
    recipients                 = recipient_override && [recipient_override] || Array.wrap(to)

    recipients.map(&to_personalization).each do |personalization, recipient|
      dynamic_template_data = data.merge(subject: [subject_prefix, subject].compact_blank.join(' '))

      if unsubscribe_group.present?
        group_id           = unsubscribe_groups[unsubscribe_group]
        send_grid_mail.asm = SendGrid::ASM.new(group_id: group_id)

        on_unsubscribe_group.call(send_grid_mail, dynamic_template_data)
      end

      personalization.add_dynamic_template_data(dynamic_template_data)
      send_grid_mail.add_personalization(personalization)
    end

    add_attachments if attachments.any?

    adapters[env_name].new(send_grid_mail)
  end


  # This means the default i18n_subject will be the name of the method in the child class, scoped by the class name
  # For example, for UserMailer.change_email(user), default_i18n_subject will be I18n.t('user_mailer.change_email.subject')
  def default_i18n_subject(called_by: nil, **args)
    mailer_method = called_by || caller.first[/`.*'/][1..-2]

    I18n.t(:subject, scope: [self.class.name.underscore, mailer_method], **args)
  end

  private

  attr_reader :send_grid_mail

  def to_personalization
    proc do |recipient|
      personalization = SendGrid::Personalization.new

      personalization.add_to(SendGrid::Email.new(email: recipient))

      [personalization, recipient]
    end
  end

  def add_attachments
    attachments.each do |filename, data|
      attachment             = SendGrid::Attachment.new
      attachment.content     = Base64.strict_encode64(data)
      attachment.type        = Mime[File.extname(filename)[1..-1]].to_s
      attachment.filename    = filename
      attachment.disposition = 'attachment'
      attachment.content_id  = filename

      send_grid_mail.add_attachment(attachment)
    end
  end

  def fallback_i18n_subject
    default_i18n_subject(called_by: caller(2, 1).first[/`.*'/][1..-2])
  end

  # This means the default template id will be the name of the method in the child class.
  # For example, for UserMailer.change_email(user), default_template_id will be SendGridMailer.confg.templates[:change_email]
  def default_template_id
    templates[caller(2, 1).first[/`.*'/][1..-2]]
  end
end
