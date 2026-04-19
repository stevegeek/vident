# frozen_string_literal: true

module Vident
  class StimulusAction < StimulusAttributeBase
    # https://stimulus.hotwired.dev/reference/actions#options
    VALID_OPTIONS = [:once, :prevent, :stop, :passive, :"!passive", :capture, :self].freeze

    # Typed descriptor for modifiers (`:once`/`:prevent`/etc., keyboard filter,
    # `@window`) that the plain Array form can't express. Hash input to the
    # parsers (`{event:, method:, ...}`) is desugared into one of these.
    class Descriptor < ::Literal::Data
      prop :method, _Union(Symbol, String)
      prop :event, _Nilable(_Union(Symbol, String)), default: nil
      prop :controller, _Nilable(String), default: nil
      prop :options, _Array(Symbol), default: -> { [] }
      prop :keyboard, _Nilable(String), default: nil
      prop :window, _Boolean, default: false
    end

    attr_reader :event, :controller, :action, :options, :keyboard, :window

    def initialize(*args, implied_controller: nil)
      @options = []
      @keyboard = nil
      @window = false
      super
    end

    def to_s
      head =
        if @event
          ev = @event.to_s
          ev = "#{ev}.#{@keyboard}" if @keyboard
          ev = "#{ev}#{@options.map { |o| ":#{o}" }.join}" if @options.any?
          ev = "#{ev}@window" if @window
          "#{ev}->"
        else
          ""
        end
      "#{head}#{@controller}##{@action}"
    end

    def data_attribute_name = "action"

    def data_attribute_value = to_s

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
      case arg
      when Descriptor then apply_descriptor(arg)
      when Hash then apply_descriptor(Descriptor.new(**arg))
      when Symbol
        @event = nil
        @controller = implied_controller_name
        @action = js_name(arg)
      when String then parse_qualified_action_string(arg)
      else raise ArgumentError, "Invalid 'action' argument type (1): #{arg.class}"
      end
    end

    # (:event, :method) or ("controller/path", :method)
    def parse_two_arguments(part1, part2)
      if part1.is_a?(Symbol) && part2.is_a?(Symbol)
        @event = part1.to_s
        @controller = implied_controller_name
        @action = js_name(part2)
      elsif part1.is_a?(String) && part2.is_a?(Symbol)
        @event = nil
        @controller = stimulize_path(part1)
        @action = js_name(part2)
      else
        raise ArgumentError, "Invalid 'action' argument types (2): #{part1.class}, #{part2.class}"
      end
    end

    # (:event, "controller/path", :method)
    def parse_three_arguments(part1, part2, part3)
      if part1.is_a?(Symbol) && part2.is_a?(String) && part3.is_a?(Symbol)
        @event = part1.to_s
        @controller = stimulize_path(part2)
        @action = js_name(part3)
      else
        raise ArgumentError, "Invalid 'action' argument types (3): #{part1.class}, #{part2.class}, #{part3.class}"
      end
    end

    def apply_descriptor(d)
      invalid = d.options - VALID_OPTIONS
      unless invalid.empty?
        raise ArgumentError,
          "Invalid action option(s) #{invalid.inspect}. Valid: #{VALID_OPTIONS.inspect}"
      end

      @event = d.event&.to_s
      @controller = d.controller ? stimulize_path(d.controller) : implied_controller_name
      @action = d.method.is_a?(Symbol) ? js_name(d.method) : d.method.to_s
      @options = d.options
      @keyboard = d.keyboard
      @window = d.window
    end

    def parse_qualified_action_string(action_string)
      if action_string.include?("->")
        event_part, controller_action = action_string.split("->", 2)
        @event = event_part
        controller_part, action_part = controller_action.split("#", 2)
        @controller = controller_part
        @action = action_part
      else
        @event = nil
        controller_part, action_part = action_string.split("#", 2)
        @controller = controller_part
        @action = action_part
      end
    end
  end
end
