# frozen_string_literal: true

module Vident
  class StimulusClass < StimulusAttributeBase
    attr_reader :controller, :class_name, :css_classes

    def to_s
      @css_classes.join(" ")
    end

    def data_attribute_name
      "#{@controller}-#{@class_name}-class"
    end

    def data_attribute_value
      to_s
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

    def parse_two_arguments(class_name, css_classes)
      if class_name.is_a?(Symbol)
        # class name on implied controller + css classes
        @controller = implied_controller_name
        @class_name = class_name.to_s.dasherize
        @css_classes = normalize_css_classes(css_classes)
      else
        raise ArgumentError, "Invalid argument types: #{class_name.class}, #{css_classes.class}"
      end
    end

    def parse_three_arguments(controller, class_name, css_classes)
      if controller.is_a?(String) && class_name.is_a?(Symbol)
        # controller + class name + css classes
        @controller = stimulize_path(controller)
        @class_name = class_name.to_s.dasherize
        @css_classes = normalize_css_classes(css_classes)
      else
        raise ArgumentError, "Invalid argument types: #{controller.class}, #{class_name.class}, #{css_classes.class}"
      end
    end

    def normalize_css_classes(css_classes)
      case css_classes
      when String
        css_classes.split(/\s+/).reject(&:empty?)
      when Array
        css_classes.map(&:to_s).reject(&:empty?)
      else
        raise ArgumentError, "CSS classes must be a String or Array, got #{css_classes.class}"
      end
    end
  end
end
