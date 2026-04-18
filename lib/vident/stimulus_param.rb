# frozen_string_literal: true

module Vident
  # Stimulus Action Parameter
  #
  # Emits `data-<controller>-<name>-param="..."` attributes on an element.
  # Stimulus exposes these to action handlers via `event.params.<camelName>`.
  # Parameters are element-scoped: every action attached to the same element
  # sees the same params.
  class StimulusParam < StimulusAttributeBase
    attr_reader :controller, :param_name, :value

    def to_s
      @value.to_s
    end

    def data_attribute_name
      "#{@controller}-#{@param_name}-param"
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
        raise ArgumentError, "Invalid number of arguments: #{args.size} (#{args.inspect}). Did you pass an array of hashes?"
      end
    end

    def parse_two_arguments(param_name, value)
      if param_name.is_a?(Symbol)
        @controller = implied_controller_name
        @param_name = param_name.to_s.dasherize
        @value = serialize_value(value)
      else
        raise ArgumentError, "Invalid argument types: #{param_name.class}, #{value.class}"
      end
    end

    def parse_three_arguments(controller, param_name, value)
      if controller.is_a?(String) && param_name.is_a?(Symbol)
        @controller = stimulize_path(controller)
        @param_name = param_name.to_s.dasherize
        @value = serialize_value(value)
      else
        raise ArgumentError, "Invalid argument types: #{controller.class}, #{param_name.class}, #{value.class}"
      end
    end

    def serialize_value(value)
      case value
      when Array, Hash
        value.to_json
      when TrueClass, FalseClass, Numeric
        value.to_s
      else
        value.to_s
      end
    end
  end
end
