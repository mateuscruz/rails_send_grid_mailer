# frozen_string_literal: true

class SendGridMailer
  class Registry
    include Enumerable

    AlreadyRegisteredError = Class.new(StandardError)
    NotFoundError          = Class.new(StandardError)

    attr_reader :default, :strict

    def initialize(strict: false)
      @registry = Hash.new
      @strict   = strict
    end

    def inspect
      registry.inspect
    end

    def default=(default)
      @default = default

      registry.default_proc = default_proc_for(default)
    end

    def [](registry_id)
      registry_key = registry_id.to_s

      raise NotFoundError.new(registry_key) if strict && !(registry.key?(registry_key) || registry.default_proc)

      registry[registry_key]
    end

    def []=(registry_id, value)
      registry_key = registry_id.to_s

      raise AlreadyRegisteredError.new(registry_id) if registry.key?(registry_key)

      registry[registry_key] = value
    end

    def invert
      inverted = Registry.new(strict: strict)

      each { |key, value| inverted[value]  = key }

      inverted
    end

    def each
      registry.each { |key, value| yield(key, value) }
    end

    def to_h
      registry.dup
    end

    private

    attr_reader :registry

    def default_proc_for(default)
      proc { |hash, key| hash[key] = default }
    end
  end
end
