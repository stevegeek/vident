# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "controller"
require_relative "base"

module Vident
  module Stimulus
    # `data-action` fragment: single action descriptor like
    # `"click->admin--users#handleClick"`.
    class Action < Base
      # Keep in sync with https://stimulus.hotwired.dev/reference/actions#options.
      VALID_OPTIONS = %i[once prevent stop passive !passive capture self].freeze

      prop :controller, Controller
      prop :method_name, String
      prop :event, _Nilable(String), default: nil
      prop :modifiers, _Array(Symbol), default: -> { [] }
      prop :keyboard, _Nilable(String), default: nil
      prop :window, _Boolean, default: false

      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Action => a]
          a
        in [Symbol => event, Action => a]
          a.with(event: event.to_s)
        in [Hash => h]
          from_descriptor(h, implied: implied)
        in [Symbol => method_sym]
          new(
            controller: implied,
            method_name: Naming.js_name(method_sym),
            event: nil
          )
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
        in [String => s]
          raise ::Vident::ParseError,
            "Action.parse: a bare String is a controller path, not a fully-qualified action descriptor. " \
            "For event/controller/method use structured args like `:click, \"path/ctrl\", :method` " \
            "or the Hash descriptor form. To parse an existing wire-format string like " \
            "\"click->ctrl#m\", call `Vident::Stimulus::Action.parse_descriptor(#{s.inspect})`."
        else
          raise ::Vident::ParseError, "Action.parse: invalid arguments #{args.inspect}"
        end
      end

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

      def self.to_data_hash(actions)
        return {} if actions.empty?
        {action: actions.map(&:to_s).join(" ")}
      end

      def self.from_descriptor(h, implied:)
        invalid_options = Array(h[:options]) - VALID_OPTIONS
        unless invalid_options.empty?
          raise ::Vident::ParseError,
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

      # Parses a wire-format Stimulus action descriptor (`"event->ctrl#method"` or
      # `"ctrl#method"`). The controller segment is taken verbatim — not re-stimulized.
      def self.parse_descriptor(s)
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
