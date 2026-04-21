# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "controller"

module Vident2
  module Stimulus
    # `data-action` fragment: single action descriptor like
    # `"click->admin--users#handleClick"`.
    #
    # Fields folded in from v1's `StimulusAction::Descriptor` — there's no
    # separate Descriptor class in V2; Hash DSL input parses directly into
    # an `Action`.
    class Action < ::Literal::Data
      # Stimulus action options (`:once`, `:prevent`, etc.). Keep in sync
      # with https://stimulus.hotwired.dev/reference/actions#options.
      VALID_OPTIONS = %i[once prevent stop passive !passive capture self].freeze

      prop :controller, Controller
      prop :method_name, String
      prop :event, _Nilable(String), default: nil
      prop :modifiers, _Array(Symbol), default: -> { [] }
      prop :keyboard, _Nilable(String), default: nil
      prop :window, _Boolean, default: false

      # `.parse(*args, implied:)` grammar mirrors v1 `StimulusAction#parse_arguments`:
      #   (Symbol)                        -> :method on implied controller, no event
      #   (String)                        -> pre-qualified "event->ctrl#method" / "ctrl#method"
      #   (Hash)                          -> keyword descriptor (method:/event:/...)
      #   (Symbol, Symbol)                -> (event, method) on implied
      #   (String, Symbol)                -> (controller_path, method) — no event
      #   (Symbol, String, Symbol)        -> (event, controller_path, method)
      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Hash => h]
          from_descriptor(h, implied: implied)
        in [Symbol => method_sym]
          new(
            controller: implied,
            method_name: Naming.js_name(method_sym),
            event: nil
          )
        in [String => s]
          parse_qualified_string(s)
        in [Symbol => event, Symbol => method_sym]
          new(
            controller: implied,
            method_name: Naming.js_name(method_sym),
            event: event.to_s
          )
        in [String => ctrl_path, Symbol => method_sym]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            method_name: Naming.js_name(method_sym),
            event: nil
          )
        in [Symbol => event, String => ctrl_path, Symbol => method_sym]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            method_name: Naming.js_name(method_sym),
            event: event.to_s
          )
        else
          raise ::Vident2::ParseError, "Action.parse: invalid arguments #{args.inspect}"
        end
      end

      # Serialised descriptor, e.g. `"click.esc:prevent@window->foo--bar#handle"`.
      def to_s
        head =
          if event
            ev = event.to_s
            ev = "#{ev}.#{keyboard}" if keyboard
            ev = "#{ev}#{modifiers.map { |o| ":#{o}" }.join}" if modifiers.any?
            ev = "#{ev}@window" if window
            "#{ev}->"
          else
            ""
          end
        "#{head}#{controller.name}##{method_name}"
      end

      def to_data_pair = [:action, to_s]

      def to_h = {action: to_s}
      alias_method :to_hash, :to_h

      # Actions space-join under a single `:action` key, preserving order.
      def self.to_data_hash(actions)
        return {} if actions.empty?
        {action: actions.map(&:to_s).join(" ")}
      end

      # `.parse({event:, method:, controller:, options:, keyboard:, window:})`
      # Keyword-descriptor entry point, used by the DSL Hash form.
      def self.from_descriptor(h, implied:)
        invalid_options = Array(h[:options]) - VALID_OPTIONS
        unless invalid_options.empty?
          raise ::Vident2::ParseError,
            "Action.parse: invalid option(s) #{invalid_options.inspect}. Valid: #{VALID_OPTIONS.inspect}"
        end

        method_raw = h.fetch(:method)
        method_name = method_raw.is_a?(Symbol) ? Naming.js_name(method_raw) : method_raw.to_s
        controller = h[:controller] ? Controller.parse(h[:controller], implied: implied) : implied
        new(
          controller: controller,
          method_name: method_name,
          event: h[:event]&.to_s,
          modifiers: Array(h[:options]),
          keyboard: h[:keyboard],
          window: h.fetch(:window, false)
        )
      end

      # Pre-qualified string form, e.g. `"click->admin/users#show"` or
      # `"admin--users#show"`. Pass-through: the controller segment is NOT
      # re-stimulized. Flagged for deprecation.
      def self.parse_qualified_string(s)
        if s.include?("->")
          event_part, ctrl_method = s.split("->", 2)
          ctrl, method = ctrl_method.split("#", 2)
          new(
            controller: Controller.new(path: ctrl, name: ctrl),
            method_name: method,
            event: event_part
          )
        else
          ctrl, method = s.split("#", 2)
          new(
            controller: Controller.new(path: ctrl, name: ctrl),
            method_name: method,
            event: nil
          )
        end
      end
    end
  end
end
