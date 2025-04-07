# frozen_string_literal: true

module Vident
  module Base
    extend ActiveSupport::Concern

    class_methods do
      def no_stimulus_controller
        @no_stimulus_controller = true
      end

      def stimulus_controller?
        !@no_stimulus_controller
      end

      # The "name" of the component from its class name and namespace. This is used to generate a HTML class name
      # that can helps identify the component type in the DOM or for styling purposes.
      def component_name
        @component_name ||= stimulus_identifier
      end

      def slots?
        registered_slots.present?
      end

      # Dont check collection params, we use kwargs
      def validate_collection_parameter!(validate_default: false)
      end

      # stimulus controller identifier
      def stimulus_identifier
        ::Vident::Base.stimulus_identifier_from_path(identifier_name_path)
      end

      def identifier_name_path
        name.underscore
      end

      private

      # Define reader & presence check method, for performance use ivar directly
      def define_attribute_delegate(attr_name)
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def #{attr_name}
            #{@attribute_ivar_names[attr_name]}
          end
  
          def #{attr_name}?
            #{@attribute_ivar_names[attr_name]}.present?
          end
        RUBY
      end
    end

    def prepare_attributes(attributes)
      raise NotImplementedError
    end

    # Override this method to perform any initialisation before attributes are set
    def before_initialise(_attrs)
    end

    # Override this method to perform any initialisation after attributes are set
    def after_initialise
    end

    def clone(overrides = {})
      new_set = to_hash.merge(**overrides)
      self.class.new(**new_set)
    end

    def inspect(klass_name = "Component")
      attr_text = attributes.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
      "#<#{self.class.name}<Vident::#{klass_name}> #{attr_text}>"
    end

    # Generate a unique ID for a component, can be overridden as required. Makes it easier to setup things like ARIA
    # attributes which require elements to reference by ID. Note this overrides the `id` accessor
    def id
      @id.presence || random_id
    end

    # If connecting an outlet to this specific component instance, use this ID
    def outlet_id
      @outlet_id ||= [stimulus_identifier, "##{id}"]
    end

    # Methods to use in component views
    # ---------------------------------

    delegate :params, to: :helpers

    # HTML and attribute definition and creation

    # Generate action/target/etc Stimulus attribute string that can be used externally to this component
    delegate :action, :target, :named_classes, to: :root

    # This can be overridden to return an array of extra class names
    def element_classes
    end

    # A HTML class name that can helps identify the component type in the DOM or for styling purposes.
    def component_class_name
      self.class.component_name
    end
    alias_method :js_event_name_prefix, :component_class_name

    # Generates the full list of HTML classes for the component
    def render_classes(erb_defined_classes = nil)
      # TODO: avoid pointless creation of arrays
      base_classes = [component_class_name] + Array.wrap(element_classes)
      base_classes += Array.wrap(erb_defined_classes) if erb_defined_classes
      classes_on_component = attribute(:html_options)&.fetch(:class, nil)
      base_classes += Array.wrap(classes_on_component) if classes_on_component
      produce_style_classes(base_classes)
    end

    def stimulus_identifier
      self.class.stimulus_identifier
    end

    # The `component` class name is used to create the controller name.
    # The path of the Stimulus controller when none is explicitly set
    def default_controller_path
      self.class.identifier_name_path
    end

    def stimulus_identifier_from_path(path)
      path.split("/").map { |p| p.to_s.dasherize }.join("--")
    end
    module_function :stimulus_identifier_from_path

    private

    def root_element_attributes
      {}
    end

    def merge_element_attributes!(element_attributes, attributes)
      attributes.each_with_object(element_attributes) do |(k, v), h|
        if h[k].is_a?(Hash)
          h[k].merge!(v)
        elsif h[k].is_a?(Array)
          h[k] << v
        else
          h[k] = v
        end
      end
    end

    def root_component_attributes(**attributes)
      @root_component_attributes ||= {}
      merge_element_attributes!(@root_component_attributes, attributes)
    end

    def stimulus_options_for_root_component
      attributes = root_element_attributes
      merge_element_attributes!(attributes, @root_component_attributes) if @root_component_attributes.present?
      stimulus_options_for_component(attributes)
    end

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

    def template_path
      self.class.template_path
    end

    def random_id
      @random_id ||= "#{component_class_name}-#{StableId.next_id_in_sequence}"
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
    end
  end
end
