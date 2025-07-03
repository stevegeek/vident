# frozen_string_literal: true

require "json"

module Vident
  class StimulusValue < StimulusAttribute
    attr_reader :controller, :value_name, :value

    def to_s
      @value.to_s
    end

    def data_attribute_name
      "#{@controller}-#{@value_name}-value"
    end

    def data_attribute_value
      @value
    end

    private

    def parse_arguments(*args)
      case args.size
      when 2
        parse_two_arguments(args[0], args[1])
      when 3
        parse_three_arguments(args[0], args[1], args[2])
      else
        raise ArgumentError, "Invalid number of arguments: #{args.size}"
      end
    end

    def parse_two_arguments(value_name, value)
      if value_name.is_a?(Symbol)
        # value name on implied controller + value
        @controller = implied_controller_name
        @value_name = value_name.to_s.dasherize
        @value = serialize_value(value)
      else
        raise ArgumentError, "Invalid argument types: #{value_name.class}, #{value.class}"
      end
    end

    def parse_three_arguments(controller, value_name, value)
      if controller.is_a?(String) && value_name.is_a?(Symbol)
        # controller + value name + value
        @controller = stimulize_path(controller)
        @value_name = value_name.to_s.dasherize
        @value = serialize_value(value)
      else
        raise ArgumentError, "Invalid argument types: #{controller.class}, #{value_name.class}, #{value.class}"
      end
    end

    def serialize_value(value)
      case value
      when Array, Hash
        value.to_json
      when TrueClass, FalseClass
        value.to_s
      when Numeric
        value.to_s
      else
        value.to_s
      end
    end
  end
end