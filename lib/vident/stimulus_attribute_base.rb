# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Vident
  class StimulusAttributeBase
    attr_reader :implied_controller

    def initialize(*args, implied_controller: nil)
      @implied_controller = implied_controller
      parse_arguments(*args)
    end

    def inspect
      "#<#{self.class.name} #{to_h}>"
    end

    def to_s
      raise NoMethodError, "Subclasses must implement to_s"
    end

    def to_h
      {data_attribute_name => data_attribute_value}
    end

    alias_method :to_hash, :to_h

    def data_attribute_name
      raise NoMethodError, "Subclasses must implement data_attribute_name"
    end

    def data_attribute_value
      raise NoMethodError, "Subclasses must implement data_attribute_value"
    end

    def implied_controller_path
      raise ArgumentError, "implied_controller is required to get implied controller path" unless implied_controller
      implied_controller.path
    end

    def implied_controller_name
      raise ArgumentError, "implied_controller is required to get implied controller name" unless implied_controller
      implied_controller.name
    end

    private

    # Convert a file path to a stimulus controller name
    def stimulize_path(path)
      path.split("/").map { |p| p.to_s.dasherize }.join("--")
    end

    # Convert a Ruby 'snake case' string to a JavaScript camel case strings
    def js_name(name)
      name.to_s.camelize(:lower)
    end

    # Subclasses must implement this method
    def parse_arguments(*args)
      raise NotImplementedError, "Subclasses must implement parse_arguments"
    end
  end
end
