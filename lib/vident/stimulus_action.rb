# frozen_string_literal: true

module Vident
  class StimulusAction < StimulusAttributeBase
    attr_reader :event, :controller, :action

    def to_s
      if @event
        "#{@event}->#{@controller}##{@action}"
      else
        "#{@controller}##{@action}"
      end
    end

    def data_attribute_name
      "action"
    end

    def data_attribute_value
      to_s
    end

    private

    def parse_arguments(*args)
      part1, part2, part3 = args

      case args.size
      when 1
        parse_single_argument(part1)
      when 2
        parse_two_arguments(part1, part2)
      when 3
        parse_three_arguments(part1, part2, part3)
      else
        raise ArgumentError, "Invalid number of 'action' arguments: #{args.size}"
      end
    end

    def parse_single_argument(arg)
      if arg.is_a?(Symbol)
        # 1 symbol arg, name of method on implied controller
        @event = nil
        @controller = implied_controller_name
        @action = js_name(arg)
      elsif arg.is_a?(String)
        # 1 string arg, fully qualified action - parse it
        parse_qualified_action_string(arg)
      else
        raise ArgumentError, "Invalid 'action' argument types (1): #{arg.class}"
      end
    end

    def parse_two_arguments(part1, part2)
      if part1.is_a?(Symbol) && part2.is_a?(Symbol)
        # 2 symbol args = event + action
        @event = part1.to_s
        @controller = implied_controller_name
        @action = js_name(part2)
      elsif part1.is_a?(String) && part2.is_a?(Symbol)
        # 1 string arg, 1 symbol = controller + action
        @event = nil
        @controller = stimulize_path(part1)
        @action = js_name(part2)
      else
        raise ArgumentError, "Invalid 'action' argument types (2): #{part1.class}, #{part2.class}"
      end
    end

    def parse_three_arguments(part1, part2, part3)
      if part1.is_a?(Symbol) && part2.is_a?(String) && part3.is_a?(Symbol)
        # 1 symbol, 1 string, 1 symbol = event + controller + action
        @event = part1.to_s
        @controller = stimulize_path(part2)
        @action = js_name(part3)
      else
        raise ArgumentError, "Invalid 'action' argument types (3): #{part1.class}, #{part2.class}, #{part3.class}"
      end
    end

    def parse_qualified_action_string(action_string)
      if action_string.include?("->")
        # Has event: "click->controller#action"
        event_part, controller_action = action_string.split("->", 2)
        @event = event_part
        controller_part, action_part = controller_action.split("#", 2)
        @controller = controller_part
        @action = action_part
      else
        # No event: "controller#action"
        @event = nil
        controller_part, action_part = action_string.split("#", 2)
        @controller = controller_part
        @action = action_part
      end
    end
  end
end
