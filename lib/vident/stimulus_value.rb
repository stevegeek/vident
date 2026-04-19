# frozen_string_literal: true

module Vident
  class StimulusValue < StimulusAttributeBase
    attr_reader :controller, :value_name, :value

    def to_s = @value.to_s

    def data_attribute_name = "#{@controller}-#{@value_name}-value"

    def data_attribute_value = @value

    private

    def parse_arguments(*args)
      case args.size
      when 2 then parse_two_arguments(*args)
      when 3 then parse_three_arguments(*args)
      else raise ArgumentError, "Invalid number of arguments: #{args.size} (#{args.inspect}). Did you pass an array of hashes?"
      end
    end

    def parse_two_arguments(value_name, value)
      raise ArgumentError, "Invalid argument types: #{value_name.class}, #{value.class}" unless value_name.is_a?(Symbol)
      @controller = implied_controller_name
      @value_name = value_name.to_s.dasherize
      @value = serialize_value(value)
    end

    def parse_three_arguments(controller, value_name, value)
      unless controller.is_a?(String) && value_name.is_a?(Symbol)
        raise ArgumentError, "Invalid argument types: #{controller.class}, #{value_name.class}, #{value.class}"
      end
      @controller = stimulize_path(controller)
      @value_name = value_name.to_s.dasherize
      @value = serialize_value(value)
    end
  end
end
