# frozen_string_literal: true

require_relative "declaration"

module Vident2
  module Internals
    # @api private
    # Fluent chain returned by `action(...)` inside a `stimulus do` block.
    # Each method mutates state and returns `self` so chains compose:
    #
    #   action(:submit).on(:form).modifier(:prevent).keyboard("enter")
    #
    # At `to_declaration` time the captured state is folded into a Hash
    # descriptor that the `Stimulus::Action` parser already understands.
    # If no chain method was called, the raw args pass through untouched
    # so existing `action :click` / `action [:click, :handle]` callsites
    # behave exactly as before.
    class ActionBuilder
      def initialize(*args)
        @args = args
        @event = nil
        @method_name = nil
        @modifiers = nil
        @keyboard = nil
        @window = false
        @controller_ref = nil
        @when_proc = nil
        @touched = false
      end

      def on(event)
        @event = event
        @touched = true
        self
      end

      def method(name)
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
