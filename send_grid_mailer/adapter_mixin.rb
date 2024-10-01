# frozen_string_literal: true

class SendGridMailer
  module AdapterMixin
    def deliver_now
      deliver
    end

    def deliver_later
      delay.deliver
    end

    def deliver
      raise NotImplementedError
    end
  end

  private_constant :AdapterMixin
end
