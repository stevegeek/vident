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
    end
  end
end
