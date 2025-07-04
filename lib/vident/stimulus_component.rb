# frozen_string_literal: true

module Vident
  module StimulusComponent
    extend ActiveSupport::Concern

    include StimulusAttributes

    # Module utilities for working with Stimulus identifiers

    def stimulus_identifier_from_path(path)
      path.split("/").map { |p| p.to_s.dasherize }.join("--")
    end
    module_function :stimulus_identifier_from_path

    # Base class for all Vident components, which provides common functionality and properties.

    class_methods do
      def no_stimulus_controller
        @no_stimulus_controller = true
      end

      def stimulus_controller? = !@no_stimulus_controller

      # The "path" of the Stimulus controller, which is used to generate the controller name.
      def stimulus_identifier_path = name.underscore

      # Stimulus controller identifier
      def stimulus_identifier = ::Vident::StimulusComponent.stimulus_identifier_from_path(stimulus_identifier_path)

      # The "name" of the component from its class name and namespace. This is used to generate an HTML class name
      # that can helps identify the component type in the DOM or for styling purposes.
      def component_name
        @component_name ||= stimulus_identifier
      end
      alias_method :component_class_name, :component_name
      # It is also used to generate the prefix for Stimulus events
      alias_method :js_event_name_prefix, :component_name
    end

    # Components have the following properties
    included do
      extend Literal::Properties

      # StimulusJS support
      # # TODO: revisit inputs and how many ways of specifying the same thing...
      prop :stimulus_controllers, _Array(_Union(String, Symbol, StimulusController, StimulusControllerCollection)), default: -> do
        if self.class.stimulus_controller?
          [default_controller_path]
        else
          []
        end
      end
      prop :stimulus_actions, _Array(_Union(String, Symbol, Array, Hash, StimulusAction, StimulusActionCollection)), default: -> { [] }
      prop :stimulus_targets, _Array(_Union(String, Symbol, Hash, StimulusTarget, StimulusTargetCollection)), default: -> { [] }
      prop :stimulus_outlets, _Array(_Union(String, Symbol, StimulusOutlet, StimulusOutletCollection)), default: -> { [] }
      prop :stimulus_outlet_host, _Nilable(Vident::Component) # A component that will host this component as an outlet
      prop :stimulus_values, _Union(_Hash(Symbol, _Any), StimulusValue, StimulusValueCollection), default: -> { {} } # TODO: instead of _Any, is it _Interface(:to_s)?
      prop :stimulus_classes, _Union(_Hash(Symbol, String), StimulusClass, StimulusClassCollection), default: -> { {} }
    end

    # If connecting an outlet to this specific component instance, use this ID
    def outlet_id
      @outlet_id ||= [stimulus_identifier, "##{id}"]
    end

    # The Stimulus controller identifier for this component
    def stimulus_identifier = self.class.stimulus_identifier

    # An HTML class name that can helps identify the component type in the DOM or for styling purposes.
    def component_class_name = self.class.component_class_name

    # The prefix for Stimulus events, which is used to generate the event names for Stimulus actions
    def js_event_name_prefix = self.class.js_event_name_prefix

    # The `component` class name is used to create the controller name.
    # The path of the Stimulus controller when none is explicitly set
    def default_controller_path = self.class.stimulus_identifier_path
  end
end
