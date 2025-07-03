# frozen_string_literal: true

module Vident
  class StimulusOutlet < StimulusAttribute
    attr_reader :controller, :outlet_name, :selector

    def initialize(*args, implied_controller:, component_id: nil)
      @component_id = component_id
      super(*args, implied_controller: implied_controller)
    end

    def to_s
      @selector
    end

    def data_attribute_name
      "#{@controller}-#{@outlet_name}-outlet"
    end

    def data_attribute_value
      @selector
    end

    private

    def parse_arguments(*args)
      case args.size
      when 1
        parse_single_argument(args[0])
      when 2
        parse_two_arguments(args[0], args[1])
      when 3
        parse_three_arguments(args[0], args[1], args[2])
      else
        raise ArgumentError, "Invalid number of arguments: #{args.size}"
      end
    end

    def parse_single_argument(arg)
      @controller = implied_controller_name
      if arg.is_a?(Symbol)
        # Single symbol: outlet name on implied controller with auto-generated selector
        outlet_identifier = arg.to_s.dasherize
        @outlet_name = outlet_identifier
        @selector = build_outlet_selector(outlet_identifier)
      elsif arg.is_a?(String)
        # Single string: outlet identifier with auto-generated selector
        @outlet_name = arg.dasherize
        @selector = build_outlet_selector(arg)
      elsif arg.is_a?(Array) && arg.size == 2
        # Array format: [outlet_identifier, css_selector]
        @outlet_name = arg[0].to_s.dasherize
        @selector = arg[1]
      elsif arg.respond_to?(:stimulus_identifier)
        # Component with stimulus_identifier
        identifier = arg.stimulus_identifier
        @outlet_name = identifier
        @selector = build_outlet_selector(identifier)
      elsif arg.respond_to?(:implied_controller_name)
        # RootComponent with implied_controller_name
        identifier = arg.implied_controller_name
        @outlet_name = identifier
        @selector = build_outlet_selector(identifier)
      else
        raise ArgumentError, "Invalid argument type: #{arg.class}"
      end
    end

    def parse_two_arguments(arg1, arg2)
      if arg1.is_a?(Symbol) && arg2.is_a?(String)
        # outlet name on implied controller + custom selector
        @controller = implied_controller_name
        @outlet_name = arg1.to_s.dasherize
        @selector = arg2
      else
        raise ArgumentError, "Invalid argument types: #{arg1.class}, #{arg2.class}"
      end
    end

    def parse_three_arguments(controller, outlet_name, selector)
      if controller.is_a?(String) && outlet_name.is_a?(Symbol) && selector.is_a?(String)
        # controller path + outlet name + selector
        @controller = stimulize_path(controller)
        @outlet_name = outlet_name.to_s.dasherize
        @selector = selector
      else
        raise ArgumentError, "Invalid argument types: #{controller.class}, #{outlet_name.class}, #{selector.class}"
      end
    end

    # Build outlet selector following the same pattern as RootComponent
    def build_outlet_selector(outlet_selector)
      prefix = @component_id ? "##{@component_id} " : ""
      "#{prefix}[data-controller~=#{outlet_selector}]"
    end
  end
end