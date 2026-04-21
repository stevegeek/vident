# frozen_string_literal: true

require_relative "declaration"

module Vident
  module Internals
    # Fluent builder returned by `action(...)`. If no chain methods are called,
    # raw args pass through untouched so bare `action :click` still works.
    class ActionBuilder
      KWARG_KEYS = %i[on call_method modifier keyboard window on_controller when].freeze

      def initialize(*args, **meta)
        @args = args
        unknown = meta.keys - KWARG_KEYS
        raise ArgumentError, "action: unknown option(s) #{unknown.inspect}. Valid: #{KWARG_KEYS.inspect}" unless unknown.empty?

        @event = meta[:on]
        @method_name = meta[:call_method]
        @modifiers = meta.key?(:modifier) ? Array(meta[:modifier]) : nil
        @keyboard = meta[:keyboard]
        @window = meta.fetch(:window, false)
        @controller_ref = meta[:on_controller]
        @when_proc = meta[:when]
        @touched = !meta.empty?
      end

      def on(event)
        @event = event
        @touched = true
        self
      end

      def call_method(name)
        @method_name = name
        @touched = true
        self
      end

      def modifier(*mods)
        (@modifiers ||= []).concat(mods)
        @touched = true
        self
      end

      def keyboard(str)
        @keyboard = str
        @touched = true
        self
      end

      def window
        @window = true
        @touched = true
        self
      end

      def on_controller(ref)
        @controller_ref = ref
        @touched = true
        self
      end

      def when(callable = nil, &block)
        @when_proc = block || callable
        self
      end

      def to_declaration
        return Declaration.new(args: @args.freeze, when_proc: @when_proc, meta: {}.freeze) unless @touched
        Declaration.new(args: [build_descriptor].freeze, when_proc: @when_proc, meta: {}.freeze)
      end

      private

      def build_descriptor
        h = base_descriptor.dup
        h[:event] = @event if @event
        h[:method] = @method_name if @method_name
        h[:options] = @modifiers.dup if @modifiers
        h[:keyboard] = @keyboard if @keyboard
        h[:window] = true if @window
        h[:controller] = @controller_ref if @controller_ref
        h
      end

      def base_descriptor
        case @args
        in [Symbol => m] then {method: m}
        in [Symbol => e, Symbol => m] then {event: e, method: m}
        in [Symbol => e, String => ctrl, Symbol => m] then {event: e, method: m, controller: ctrl}
        in [Hash => h] then h
        else {}
        end
      end
    end
  end
end
