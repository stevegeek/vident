# frozen_string_literal: true

require_relative "../internals/registry"
require_relative "../stimulus/collection"

module Vident
  module Capabilities
    module StimulusMutation
      extend ActiveSupport::Concern

      included do
        unless ancestors.include?(::Vident::Capabilities::Identifiable)
          raise ::Vident::DeclarationError,
            "#{name || "anonymous component"} must include Vident::Capabilities::Identifiable before Vident::Capabilities::StimulusMutation"
        end
      end

      ::Vident::Internals::Registry.each do |kind|
        define_method(:"add_stimulus_#{kind.plural_name}") do |input|
          raise_if_sealed!
          values = unwrap_mutator_input(kind, input)
          values.each { |v| @__vident_draft.public_send(:"add_#{kind.name}", v) if v }
          self
        end
      end

      private

      # Array input is ONE entry — does not splat across multiple entries
      # (mirrors the DSL's plural→singular forwarding).
      #
      # Hash input is only accepted for keyed kinds (values, params, class_maps,
      # outlets) and Actions. Passing a Hash to a non-keyed, non-Action kind
      # (controllers, targets) raises ParseError — use a String or Symbol instead.
      def unwrap_mutator_input(kind, input)
        case input
        in nil
          []
        in ^(kind.value_class) => v
          [v]
        in ::Vident::Stimulus::Collection => coll
          coll.items
        in Hash => h if kind.keyed?
          h.map { |name, raw| kind.value_class.parse(name, raw, implied: implied_controller, component_id: id) }
        in Hash => h if kind.value_class == ::Vident::Stimulus::Action
          [kind.value_class.parse(h, implied: implied_controller, component_id: id)]
        in Hash
          raise ::Vident::ParseError,
            "add_stimulus_#{kind.plural_name}: Hash input is not valid for #{kind.plural_name}. " \
            "Use a String or Symbol instead, e.g. add_stimulus_#{kind.plural_name}(\"name\"). " \
            "Hash input is only accepted for keyed kinds (values, params, classes, outlets) and actions."
        in Array => a
          [kind.value_class.parse(*a, implied: implied_controller, component_id: id)]
        else
          [kind.value_class.parse(input, implied: implied_controller, component_id: id)]
        end
      end
    end
  end
end
