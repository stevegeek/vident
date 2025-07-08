# frozen_string_literal: true

module Vident
  module ComponentAttributeResolver
    private

    # FIXME: in a view_component the parsing of html_options might have to be in `before_render`
    def prepare_component_attributes
      prepare_stimulus_collections

      # Add stimulus attributes from DSL first (lower precedence)
      add_stimulus_attributes_from_dsl

      # Process root_element_attributes (higher precedence)
      extra = root_element_attributes
      @html_options = (extra[:html_options] || {}).merge(@html_options) if extra.key?(:html_options)
      @html_options[:class] = render_classes(extra[:classes])
      @html_options[:id] = (extra[:id] || id) unless @html_options.key?(:id)
      @element_tag = extra[:element_tag] if extra.key?(:element_tag)

      add_stimulus_controllers(extra[:stimulus_controllers]) if extra.key?(:stimulus_controllers)
      add_stimulus_actions(extra[:stimulus_actions]) if extra.key?(:stimulus_actions)
      add_stimulus_targets(extra[:stimulus_targets]) if extra.key?(:stimulus_targets)
      add_stimulus_outlets(extra[:stimulus_outlets]) if extra.key?(:stimulus_outlets)
      add_stimulus_values(extra[:stimulus_values]) if extra.key?(:stimulus_values)
      add_stimulus_classes(extra[:stimulus_classes]) if extra.key?(:stimulus_classes)
    end

    # Add stimulus attributes from DSL declarations using existing add_* methods
    def add_stimulus_attributes_from_dsl
      dsl_attrs = self.class.stimulus_dsl_attributes(self)
      return if dsl_attrs.empty?

      # Use existing add_* methods to integrate DSL attributes
      add_stimulus_controllers(dsl_attrs[:stimulus_controllers]) if dsl_attrs[:stimulus_controllers]
      add_stimulus_actions(dsl_attrs[:stimulus_actions]) if dsl_attrs[:stimulus_actions]
      add_stimulus_targets(dsl_attrs[:stimulus_targets]) if dsl_attrs[:stimulus_targets]
      add_stimulus_outlets(dsl_attrs[:stimulus_outlets]) if dsl_attrs[:stimulus_outlets]

      # Add static values (now includes resolved proc values)
      add_stimulus_values(dsl_attrs[:stimulus_values]) if dsl_attrs[:stimulus_values]

      # Resolve and add values from props
      if dsl_attrs[:stimulus_values_from_props]
        resolved_values = resolve_values_from_props(dsl_attrs[:stimulus_values_from_props])
        add_stimulus_values(resolved_values) unless resolved_values.empty?
      end

      add_stimulus_classes(dsl_attrs[:stimulus_classes]) if dsl_attrs[:stimulus_classes]
    end

    # Prepare stimulus collections and implied controller path from the given attributes, called after initialization
    def prepare_stimulus_collections # Convert raw attributes to stimulus attribute collections
      @stimulus_controllers_collection = stimulus_controllers(*Array.wrap(@stimulus_controllers))
      @stimulus_actions_collection = stimulus_actions(*Array.wrap(@stimulus_actions))
      @stimulus_targets_collection = stimulus_targets(*Array.wrap(@stimulus_targets))
      @stimulus_outlets_collection = stimulus_outlets(*Array.wrap(@stimulus_outlets))
      @stimulus_values_collection = stimulus_values(*Array.wrap(@stimulus_values))
      @stimulus_classes_collection = stimulus_classes(*Array.wrap(@stimulus_classes))

      @stimulus_outlet_host.add_stimulus_outlets(self) if @stimulus_outlet_host
    end

    # Build stimulus data attributes using collection splat
    def stimulus_data_attributes
      StimulusDataAttributeBuilder.new(
        controllers: @stimulus_controllers_collection,
        actions: @stimulus_actions_collection,
        targets: @stimulus_targets_collection,
        outlets: @stimulus_outlets_collection,
        values: @stimulus_values_collection,
        classes: @stimulus_classes_collection
      ).build
    end
  end
end
