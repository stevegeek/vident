# frozen_string_literal: true

require_relative "../stimulus/controller"
require_relative "../stimulus/action"
require_relative "../stimulus/target"
require_relative "../stimulus/outlet"
require_relative "../stimulus/value"
require_relative "../stimulus/param"
require_relative "../stimulus/class_map"

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
        prop :stimulus_controllers,
          _Array(_Union(String, Symbol, ::Vident::Stimulus::Controller)),
          default: -> { [] }
        prop :stimulus_actions,
          _Array(_Union(String, Symbol, Array, Hash, ::Vident::Stimulus::Action)),
          default: -> { [] }
        prop :stimulus_targets,
          _Array(_Union(String, Symbol, Array, ::Vident::Stimulus::Target)),
          default: -> { [] }
        prop :stimulus_outlets,
          _Array(_Union(String, Symbol, Array, ::Vident::Stimulus::Outlet)),
          default: -> { [] }
        prop :stimulus_outlet_host, _Nilable(::Vident::Component)
        prop :stimulus_values,
          _Union(_Hash(Symbol, _Any), Array, ::Vident::Stimulus::Value),
          default: -> { {} }
        prop :stimulus_params,
          _Union(_Hash(Symbol, _Any), Array, ::Vident::Stimulus::Param),
          default: -> { {} }
        prop :stimulus_classes,
          _Union(_Hash(Symbol, _Any), Array, ::Vident::Stimulus::ClassMap),
          default: -> { {} }
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
