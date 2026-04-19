# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

require "json"

module Vident
  class StimulusAttributeBase
    # `"admin/users"` → `"admin--users"`; accepts Symbol or String.
    def self.stimulize_path(path)
      path.to_s.split("/").map(&:dasherize).join("--")
    end

    # `:my_thing` → `"myThing"`
    def self.js_name(name)
      name.to_s.camelize(:lower)
    end

    attr_reader :implied_controller

    def initialize(*args, implied_controller: nil)
      @implied_controller = implied_controller
      parse_arguments(*args)
    end

    def inspect = "#<#{self.class.name} #{to_h}>"

    def to_s = raise(NoMethodError, "Subclasses must implement to_s")

    def to_h = {data_attribute_name => data_attribute_value}

    alias_method :to_hash, :to_h

    def data_attribute_name = raise(NoMethodError, "Subclasses must implement data_attribute_name")

    def data_attribute_value = raise(NoMethodError, "Subclasses must implement data_attribute_value")

    def implied_controller_path
      raise ArgumentError, "implied_controller is required to get implied controller path" unless implied_controller
      implied_controller.path
    end

    def implied_controller_name
      raise ArgumentError, "implied_controller is required to get implied controller name" unless implied_controller
      implied_controller.name
    end

    private

    def stimulize_path(path) = self.class.stimulize_path(path)

    def js_name(name) = self.class.js_name(name)

    # Arrays/Hashes serialise as JSON; everything else via `to_s` (which is how
    # `Vident::StimulusNull` emits the literal `"null"`).
    def serialize_value(value)
      case value
      when Array, Hash then value.to_json
      else value.to_s
      end
    end

    def parse_arguments(*args)
      raise NotImplementedError, "Subclasses must implement parse_arguments"
    end
  end
end
