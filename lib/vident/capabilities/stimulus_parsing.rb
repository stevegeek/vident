# frozen_string_literal: true

require_relative "../internals/registry"
require_relative "../stimulus/collection"

module Vident
  module Capabilities
    # Include order: Identifiable must be included before this module
    # (generated methods call `implied_controller` and `id`).
    module StimulusParsing
      extend ActiveSupport::Concern

      included do
        unless ancestors.include?(::Vident::Capabilities::Identifiable)
          raise ::Vident::DeclarationError,
            "#{name || "anonymous component"} must include Vident::Capabilities::Identifiable before Vident::Capabilities::StimulusParsing"
        end
      end

      ::Vident::Internals::Registry.each do |kind|
        define_method(:"stimulus_#{kind.singular_name}") do |*args|
          return args.first if args.length == 1 && args.first.is_a?(kind.value_class)
          kind.value_class.parse(*args, implied: implied_controller, component_id: id)
        end

        define_method(:"stimulus_#{kind.plural_name}") do |*args|
          return ::Vident::Stimulus::Collection.new(kind: kind, items: []) if args.empty? || args.all?(&:nil?)
          return args.first if args.length == 1 && args.first.is_a?(::Vident::Stimulus::Collection)

          items = []
          args.each do |arg|
            case arg
            in ^(kind.value_class) => v
              items << v
            in ::Vident::Stimulus::Collection => coll
              items.concat(coll.items)
            in Hash => h if kind.keyed?
              h.each { |name, val| items << kind.value_class.parse(name, val, implied: implied_controller, component_id: id) }
            in Hash => h
              items << kind.value_class.parse(h, implied: implied_controller, component_id: id)
            in Array => a
              items << kind.value_class.parse(*a, implied: implied_controller, component_id: id)
            else
              items << kind.value_class.parse(arg, implied: implied_controller, component_id: id)
            end
          end
          ::Vident::Stimulus::Collection.new(kind: kind, items: items)
        end
      end

      # Class-level builders reject cross-controller forms (receiver's implied
      # controller would be silently ignored) — call `Vident::Stimulus::*.parse`
      # directly for those. `stimulus_outlet` additionally requires an explicit
      # selector (no component_id to auto-scope).
      class_methods do
        def stimulus_controller
          implied_controller_for_class
        end

        def stimulus_target(*args)
          case args
          in [String => ctrl_path, Symbol]
            raise ::Vident::ParseError,
              "#{name}.stimulus_target does not accept cross-controller form at class level. " \
              "Call Vident::Stimulus::Target.parse(#{ctrl_path.inspect}, ...) directly."
          else
            ::Vident::Stimulus::Target.parse(*args, implied: implied_controller_for_class)
          end
        end

        def stimulus_action(*args)
          case args
          in [String => ctrl_path, Symbol]
            raise ::Vident::ParseError,
              "#{name}.stimulus_action does not accept cross-controller form at class level. " \
              "Call Vident::Stimulus::Action.parse(#{ctrl_path.inspect}, ...) directly."
          in [Symbol, String, Symbol]
            raise ::Vident::ParseError,
              "#{name}.stimulus_action does not accept cross-controller form at class level. " \
              "Call Vident::Stimulus::Action.parse directly."
          else
            ::Vident::Stimulus::Action.parse(*args, implied: implied_controller_for_class)
          end
        end

        def stimulus_value(*args)
          case args
          in [String, Symbol, *]
            raise ::Vident::ParseError,
              "#{name}.stimulus_value does not accept cross-controller form at class level. " \
              "Call Vident::Stimulus::Value.parse directly."
          else
            ::Vident::Stimulus::Value.parse(*args, implied: implied_controller_for_class)
          end
        end

        def stimulus_param(*args)
          case args
          in [String, Symbol, *]
            raise ::Vident::ParseError,
              "#{name}.stimulus_param does not accept cross-controller form at class level. " \
              "Call Vident::Stimulus::Param.parse directly."
          else
            ::Vident::Stimulus::Param.parse(*args, implied: implied_controller_for_class)
          end
        end

        def stimulus_class(*args)
          case args
          in [String, Symbol, *]
            raise ::Vident::ParseError,
              "#{name}.stimulus_class does not accept cross-controller form at class level. " \
              "Call Vident::Stimulus::ClassMap.parse directly."
          else
            ::Vident::Stimulus::ClassMap.parse(*args, implied: implied_controller_for_class)
          end
        end

        def stimulus_outlet(*args)
          case args
          in [Symbol => _name, ::Vident::Stimulus::Selector] | [String => _name, ::Vident::Stimulus::Selector]
            ::Vident::Stimulus::Outlet.parse(*args, implied: implied_controller_for_class)
          else
            raise ::Vident::ParseError,
              "#{name}.stimulus_outlet requires (name, Vident::Selector(...)) — no component_id at class level. " \
              "Use instance-level `component.stimulus_outlet(:name)` for auto-selector, " \
              "or `#{name}.stimulus_outlet(:name, Vident::Selector('.css'))` for a verbatim selector."
          end
        end

        private

        # Memoised on the class's own singleton — Ruby doesn't share
        # singleton ivars through inheritance, so subclasses get their own.
        def implied_controller_for_class
          @__vident_class_implied_controller ||= ::Vident::Stimulus::Controller.new(
            path: stimulus_identifier_path,
            name: stimulus_identifier
          )
        end
      end
    end
  end
end
