# frozen_string_literal: true

module Vident
  module Component
    extend ActiveSupport::Concern

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
      prop :stimulus_controllers, _Array(_Union(String, Symbol)), default: -> { [] } # TODO: revisit how we define controllers
      prop :stimulus_actions, _Array(_Union(String, Symbol, Array, Hash)), default: -> { [] } # TODO: revisit how we define actions
      prop :stimulus_targets, _Array(_Union(String, Symbol, Hash)), default: -> { [] } # TODO: revisit how we define targets
      prop :stimulus_outlets, _Array(_Union(String, Symbol)), default: -> { [] }
      prop :stimulus_outlet_host, _Nilable(Vident::Component)
      prop :stimulus_values, _Array(_Hash(Symbol, _Any)), default: -> { [] } # TODO: instead of _Any, is it _Interface(:to_s)?
      prop :stimulus_classes, _Hash(Symbol, String), default: -> { {} }
    end

    # Override this method to perform any initialisation before attributes are set
    def before_initialize(_attrs)
    end

    # Override this method to perform any initialisation after attributes are set
    def after_initialize
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

    # Generate a random ID for the component, which is used to ensure uniqueness in the DOM.
    def random_id
      @random_id ||= "#{component_class_name}-#{StableId.next_id_in_sequence}"
    end

    def stimulus_options_for_root_component = stimulus_options_for_component(root_element_attributes)

    # Generates the full list of HTML classes for the component
    def render_classes(extra_classes = nil)  = class_list_builder.build(extra_classes)

    # Prepare the stimulus attributes for a StimulusComponent
    def stimulus_options_for_component(options)
      # Add pending actions
      all_actions = attribute(:actions) + Array.wrap(options[:actions])
      all_actions += @pending_actions if @pending_actions&.any?

      # Add pending targets
      all_targets = attribute(:targets) + Array.wrap(options[:targets])
      all_targets += @pending_targets if @pending_targets&.any?

      # Merge pending named classes
      named_classes_option = merge_stimulus_option(options, :named_classes)
      if @pending_named_classes&.any?
        named_classes_option = named_classes_option.merge(@pending_named_classes)
      end

      {
        id: respond_to?(:id) ? id : (attribute(:id) || options[:id]),
        element_tag: attribute(:element_tag) || options[:element_tag] || :div,
        html_options: prepare_html_options(options[:html_options]),
        controllers: (
          self.class.stimulus_controller? ? [default_controller_path] : []
        ) + Array.wrap(options[:controllers]) + attribute(:controllers),
        actions: all_actions,
        targets: all_targets,
        outlets: attribute(:outlets) + Array.wrap(options[:outlets]),
        outlet_host: attribute(:outlet_host),
        named_classes: named_classes_option,
        values: prepare_stimulus_option(options, :values)
      }
    end

    def prepare_html_options(erb_options)
      # Options should override in this order:
      # - defined on component class methods (lowest priority)
      # - defined by passing to component erb
      # - defined by passing to component constructor (highest priority)
      options = erb_options&.except(:class) || {}
      classes_from_view = Array.wrap(erb_options[:class]) if erb_options&.key?(:class)
      options[:class] = render_classes(classes_from_view)
      options.merge!(attribute(:html_options).except(:class)) if attribute(:html_options)
      options
    end

    # TODO: deprecate the ability to set via method on class (responds_to?) and just use component attributes
    # or attributes passed to parent_element
    def prepare_stimulus_option(options, name)
      resolved = respond_to?(name) ? Array.wrap(send(name)) : []
      resolved.concat(Array.wrap(attribute(name)))
      resolved.concat(Array.wrap(options[name]))
      resolved
    end

    def merge_stimulus_option(options, name)
      (attribute(name) || {}).merge(options[name] || {})
    end

    def produce_style_classes(class_names)
      dedupe_view_component_classes(class_names)
    end

    CLASSNAME_SEPARATOR = " "

    # Join all the various class definisions possible and dedupe
    def dedupe_view_component_classes(html_classes)
      html_classes.reject!(&:blank?)

      # Join, then dedupe.
      # This ensures that entries from the classes array such as "a b", "a", "b" are correctly deduped.
      # Note we are trying to do this with less allocations to avoid GC churn
      # classes = classes.join(" ").split(" ").uniq
      html_classes.map! { |x| x.include?(CLASSNAME_SEPARATOR) ? x.split(CLASSNAME_SEPARATOR) : x }
        .flatten!
      html_classes.uniq!
      html_classes.present? ? html_classes.join(CLASSNAME_SEPARATOR) : nil
    # Get or create a class list builder instance
    # Automatically detects if Tailwind module is included and TailwindMerge gem is available
    def class_list_builder
      @class_list_builder ||= ClassListBuilder.new(
        tailwind_merger:,
        component_class_name:,
        element_classes:,
        html_class: attribute(:html_options)&.fetch(:class, nil)
      )
    end
    end
  end
end
