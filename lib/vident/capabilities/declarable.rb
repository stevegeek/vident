# frozen_string_literal: true

require_relative "../types"

module Vident
  module Capabilities
    module Declarable
      extend ActiveSupport::Concern

      included do
        extend Literal::Properties

        prop :element_tag, Symbol, default: :div
        prop :id, _Nilable(String)
        prop :classes, _Union(String, _Array(String)), default: -> { [] }
        prop :html_options, Hash, default: -> { {} }

        # `stimulus_controllers:` APPENDS to the implied controller (which
        # seeds first unless `no_stimulus_controller`).
        prop :stimulus_controllers, ::Vident::Types::StimulusControllers, default: -> { [] }
        prop :stimulus_actions, ::Vident::Types::StimulusActions, default: -> { [] }
        prop :stimulus_targets, ::Vident::Types::StimulusTargets, default: -> { [] }
        prop :stimulus_outlets, ::Vident::Types::StimulusOutlets, default: -> { [] }
        prop :stimulus_outlet_host, _Nilable(::Vident::Component)
        prop :stimulus_values, ::Vident::Types::StimulusValues, default: -> { {} }
        prop :stimulus_params, ::Vident::Types::StimulusParams, default: -> { {} }
        prop :stimulus_classes, ::Vident::Types::StimulusClasses, default: -> { {} }
      end

      class_methods do
        def prop_names
          literal_properties.properties_index.keys.map(&:to_sym)
        end
      end

      def prop_names = self.class.prop_names
    end
  end
end
