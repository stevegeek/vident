# frozen_string_literal: true

module Vident
  module ComponentAttributeResolver
    include Stimulus::Naming

    private

    # Prepare attributes set at initialization, which will later be merged together before rendering.
    def prepare_component_attributes
      prepare_stimulus_collections

      # Add stimulus attributes from DSL first (lower precedence)
      add_stimulus_attributes_from_dsl

      # Process root_element_attributes (higher precedence)
      extra = root_element_attributes
      @html_options = (extra[:html_options] || {}).merge(@html_options) if extra.key?(:html_options)
      @root_element_attributes_classes = extra[:classes]
      @root_element_attributes_id = extra[:id] || id
      @element_tag = extra[:element_tag] if extra.key?(:element_tag)

      Stimulus::PRIMITIVES.each do |primitive|
        send(mutator_method(primitive), extra[primitive.key]) if extra.key?(primitive.key)
      end
    end

    def resolve_root_element_attributes_before_render(root_element_html_options = nil)
      extra = root_element_html_options || {}

      # Options set on component at render time take precedence over attributes set by methods on the component
      # or attributes passed to root_element in the template
      final_attributes = {
        data: stimulus_data_attributes  # Lowest precedence
      }
      if root_element_html_options.present? # Mid precedence
        root_element_tag_html_options_merge(final_attributes, root_element_html_options)
      end
      if @html_options.present? # Highest precedence
        root_element_tag_html_options_merge(final_attributes, @html_options)
      end
      final_attributes[:class] = render_classes(extra[:class])
      final_attributes[:id] = (extra[:id] || @root_element_attributes_id) unless final_attributes.key?(:id)
      final_attributes
    end

    def root_element_tag_html_options_merge(final_attributes, other_html_options)
      if other_html_options[:data].present?
        final_attributes[:data].merge!(other_html_options[:data])
      end
      final_attributes.merge!(other_html_options.except(:data))
    end

    # Run every DSL attribute through its `add_stimulus_*` mutator. `values_from_props`
    # is a sidecar on values, resolved at instance render time.
    def add_stimulus_attributes_from_dsl
      dsl_attrs = self.class.stimulus_dsl_attributes(self)
      return if dsl_attrs.empty?

      Stimulus::PRIMITIVES.each do |primitive|
        value = dsl_attrs[primitive.key]
        send(mutator_method(primitive), value) if value
      end

      if dsl_attrs[:stimulus_values_from_props]
        resolved_values = resolve_values_from_props(dsl_attrs[:stimulus_values_from_props])
        add_stimulus_values(resolved_values) unless resolved_values.empty?
      end
    end

    # Seed the collection ivars from each prop's raw value.
    def prepare_stimulus_collections
      Stimulus::PRIMITIVES.each do |primitive|
        raw = instance_variable_get(prop_ivar(primitive))
        collection = send(primitive.key, *Array.wrap(raw))
        instance_variable_set(collection_ivar(primitive), collection)
      end

      @stimulus_outlet_host.add_stimulus_outlets(self) if @stimulus_outlet_host
    end

    def stimulus_data_attributes
      collections = Stimulus::PRIMITIVES.to_h { |primitive| [primitive.name, instance_variable_get(collection_ivar(primitive))] }
      StimulusDataAttributeBuilder.new(**collections).build
    end
  end
end
