# rails_send_grid_mailer

ActionMailer-like library for SendGrid emails using dynamic templates!

# Dependencies

- `nokogiri`
- `sendgrid-ruby`
- `ruby-handlebars`

# How to use it

1. Copy the contents of this repo to your rails lib/ folder
2. Add this to an initializer:

```ruby
require 'send_grid_mailer'
require 'send_grid_mailer/api_adapter'
require 'send_grid_mailer/smtp_adapter' if Rails.env.development? # or any other env you wish to use SMTP for
require 'send_grid_mailer/test_adapter' if Rails.env.test?

SendGridMailer.configure do |config|
  # these are examples. Modify to suit your needs
  templates = {
    'hello-world' => 'hello-world-template-id-on-sendgrid'
  }.with_indifferent_access

  unsubscribe_groups = {
    'all-emails' => 'all-emails-group-id-on-sendgrid'
  }.with_indifferent_access

  config.api_key            = 'your sendgrid api_key'
  config.sender             = 'no-reply@mycustomdomain.com' #your_default_mail_sender
  config.logger             = Rails.logger # Or any other logger you prefer
  config.recipient_override = 'john.doe@example.com' # if you wish to forward all mails to one address, useful when testing
  config.subject_prefix     = "[#{Rails.env.to_s.upcase}]" if %w[sandbox staging development].include?(Rails.env) # If you wish to tag your email subjects to debug

  config.adapters.default       = SendGridMailer::ApiAdapter # default to sending via API
  config.adapters[:development] = SendGridMailer::SMTPAdapter if defined?(SendGridMailer::SMTPAdapter)
  config.adapters[:test]        = SendGridMailer::TestAdapter if defined?(SendGridMailer::TestAdapter)

  unsubscribe_groups.each do |group_name, group_id|
    config.unsubscribe_groups[group_name] = group_id
  end
  config.unsubscribe_groups.default = unsubscribe_groups.fetch(:all_emails)

  templates.except(:default).each do |template_name, template_id|
    config.templates[template_name] = template_id
  end
end
```
