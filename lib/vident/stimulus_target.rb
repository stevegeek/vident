# frozen_string_literal: true

module Vident
  class StimulusTarget < StimulusAttributeBase
    attr_reader :controller, :name

    def to_s
      @name
    end

    # Returns the data attribute name for this target
    def data_attribute_name
      "#{@controller}-target"
    end

    # Returns the target name value for the data attribute
    def data_attribute_value
      @name
    end

    private

    def parse_arguments(*args)
      case args.size
      when 1
        parse_single_argument(args[0])
      when 2
        parse_two_arguments(args[0], args[1])
      else
        raise ArgumentError, "Invalid number of arguments: #{args.size}"
      end
    end

    def parse_single_argument(arg)
      @controller = implied_controller_name
      if arg.is_a?(Symbol)
        # 1 symbol arg, name of target on implied controller
        @name = js_name(arg)
      elsif arg.is_a?(String)
        # 1 string arg, assume it's a target name on implied controller
        @name = arg
      else
        raise ArgumentError, "Invalid argument type: #{arg.class}"
      end
    end

    def parse_two_arguments(part1, part2)
      if part1.is_a?(String) && part2.is_a?(Symbol)
        # 1 string arg, 1 symbol = controller + target
        @controller = stimulize_path(part1)
        @name = js_name(part2)
      else
        raise ArgumentError, "Invalid argument types: #{part1.class}, #{part2.class}"
      end
    end
  end
end
