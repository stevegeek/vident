# frozen_string_literal: true

module Vident
  # `data-<controller>-<name>-param="..."` — readable on the JS side as
  # `event.params.<camelName>`. Element-scoped: every action on the element
  # sees the same params.
  class StimulusParam < StimulusAttributeBase
    attr_reader :controller, :param_name, :value

    def to_s = @value.to_s

    def data_attribute_name = "#{@controller}-#{@param_name}-param"

    def data_attribute_value = @value

    private

    def parse_arguments(*args)
      case args.size
      when 2 then parse_two_arguments(*args)
      when 3 then parse_three_arguments(*args)
      else raise ArgumentError, "Invalid number of arguments: #{args.size} (#{args.inspect}). Did you pass an array of hashes?"
      end
    end

    def parse_two_arguments(param_name, value)
      raise ArgumentError, "Invalid argument types: #{param_name.class}, #{value.class}" unless param_name.is_a?(Symbol)
      @controller = implied_controller_name
      @param_name = param_name.to_s.dasherize
      @value = serialize_value(value)
    end

    def parse_three_arguments(controller, param_name, value)
      unless controller.is_a?(String) && param_name.is_a?(Symbol)
        raise ArgumentError, "Invalid argument types: #{controller.class}, #{param_name.class}, #{value.class}"
      end
      @controller = stimulize_path(controller)
      @param_name = param_name.to_s.dasherize
      @value = serialize_value(value)
    end
  end
end
