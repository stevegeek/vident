# frozen_string_literal: true

module Vident
  module Component
    extend ActiveSupport::Concern

    include StimulusAttributes
    include TagHelper
    include Tailwind

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
      def stimulus_identifier = ::Vident::Component.stimulus_identifier_from_path(stimulus_identifier_path)

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

      prop :id, _Nilable(String)
      prop :html_options, Hash, default: -> { {} }
      prop :element_tag, Symbol, default: :div

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
      prop :stimulus_values, _Array(_Union(_Hash(Symbol, _Any), StimulusValue, StimulusValueCollection)), default: -> { [] } # TODO: instead of _Any, is it _Interface(:to_s)?
      prop :stimulus_classes, _Union(_Hash(Symbol, String), StimulusClass, StimulusClassCollection), default: -> { {} }
    end

    # Override this method to perform any initialisation after attributes are set
    def after_component_initialize
    end

    # This can be overridden to return an array of extra class names, or a string of class names.
    def element_classes
    end

    # Properties/attributes passed to the "root" element of the component. You normally override this method to
    # return a hash of attributes that should be applied to the root element of your component.
    def root_element_attributes
      {}
    end

    # Create a new component instance with optional overrides for properties.
    def clone(overrides = {}) = self.class.new(**to_h.merge(**overrides))

    def inspect(klass_name = "Component")
      attr_text = to_h.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
      "#<#{self.class.name}<Vident::#{klass_name}> #{attr_text}>"
    end

    # Generate a unique ID for a component, can be overridden as required. Makes it easier to setup things like ARIA
    # attributes which require elements to reference by ID. Note this overrides the `id` accessor
    def id = @id.presence || random_id

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

    private

    def root_element(&block)
      raise NoMethodError, "You must implement the `root_element` method in your component"
    end

    def root(...)
      root_element(...)
    end

    alias_method :parent_element, :root

    # Called by Literal::Properties after the component is initialized.
    def after_initialize
      prepare_stimulus_collections
      after_component_initialize if respond_to?(:after_component_initialize)
    end

    # Generate a random ID for the component, which is used to ensure uniqueness in the DOM.
    def random_id
      @random_id ||= "#{component_class_name}-#{StableId.next_id_in_sequence}"
    end

    # Generates the full list of HTML classes for the component
    def render_classes(extra_classes = nil) = class_list_builder.build(extra_classes)

    # Get or create a class list builder instance
    # Automatically detects if Tailwind module is included and TailwindMerge gem is available
    def class_list_builder
      @class_list_builder ||= ClassListBuilder.new(
        tailwind_merger:,
        component_class_name:,
        element_classes:,
        html_class: @html_options&.fetch(:class, nil)
      )
    end
    #
    # def stimulus_options_for_root_component = stimulus_options_for_component(root_element_attributes)
    #
    # # Prepare the stimulus attributes for a StimulusComponent
    # def stimulus_options_for_component(options)
    #   stimulus_options_builder.build(
    #     options,
    #     pending_actions: @pending_actions || [],
    #     pending_targets: @pending_targets || [],
    #     pending_named_classes: @pending_named_classes || {}
    #   )
    # end
    #
    # # Get or create a stimulus options builder instance
    # def stimulus_options_builder
    #   @stimulus_options_builder ||= StimulusOptionsBuilder.new(
    #     id: respond_to?(:id) ? id : attribute(:id),
    #     element_tag: @element_tag,
    #     html_options: @html_options,
    #     stimulus_controllers: @stimulus_controllers,
    #     stimulus_actions: @stimulus_actions,
    #     stimulus_targets: @stimulus_targets,
    #     stimulus_outlets: @stimulus_outlets,
    #     stimulus_outlet_host: @stimulus_outlet_host,
    #     stimulus_classes: @stimulus_classes,
    #     stimulus_values: @stimulus_values,
    #     default_controller_path: default_controller_path,
    #     stimulus_controller_enabled: self.class.stimulus_controller?,
    #     class_list_builder: class_list_builder
    #   )
    # end
  end
end
