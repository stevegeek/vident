# frozen_string_literal: true

module Vident
  module Component
    extend ActiveSupport::Concern

    # Base class for all Vident components, which provides common functionality and properties.
    included do
      # The HTML tag to use for the root element of the component, defaults to `:div`.
      prop :element_tag, Symbol, default: :div
      # ID of the component. If not set, a random ID is generated.
      prop :id, _Nilable(String)
      # Classes to apply to the root element (they add to the `class` attribute)
      prop :classes, _Union(String, _Array(String)), default: -> { [] }
      # HTML options to apply to the root element (will merge into and potentially override html_options of the element)
      prop :html_options, Hash, default: -> { {} }
    end

    include StimulusComponent
    include ComponentClassLists
    include ComponentAttributeResolver

    include TagHelper
    include Tailwind

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

    private

    # Called by Literal::Properties after the component is initialized.
    def after_initialize
      prepare_component_attributes
      after_component_initialize if respond_to?(:after_component_initialize)
    end

    def root_element(&block)
      raise NoMethodError, "You must implement the `root_element` method in your component"
    end

    def root(...)
      root_element(...)
    end
    alias_method :parent_element, :root

    # Generate a random ID for the component, which is used to ensure uniqueness in the DOM.
    def random_id
      @random_id ||= "#{component_class_name}-#{StableId.next_id_in_sequence}"
    end
  end
end
