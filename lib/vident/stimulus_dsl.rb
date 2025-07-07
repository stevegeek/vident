# frozen_string_literal: true

module Vident
  module StimulusDSL
    extend ActiveSupport::Concern

    class StimulusBuilder
      def initialize
        @actions = []
        @targets = []
        @values = {}
        @values_from_props = []
        @classes = {}
        @outlets = {}
      end

      def actions(*action_names)
        @actions.concat(action_names)
        self
      end

      def targets(*target_names)
        @targets.concat(target_names)
        self
      end

      def values(**value_hash)
        # Handle keyword arguments: values name: "default_value", count: 42
        @values.merge!(value_hash) unless value_hash.empty?
        self
      end
      
      def values_from_props(*prop_names)
        # Handle prop names that should be mapped as stimulus values
        @values_from_props.concat(prop_names)
        self
      end

      def classes(**class_mappings)
        @classes.merge!(class_mappings)
        self
      end

      def outlets(**outlet_mappings)
        @outlets.merge!(outlet_mappings) unless outlet_mappings.empty?
        self
      end

      def to_attributes
        attrs = {}
        attrs[:stimulus_actions] = @actions.dup unless @actions.empty?
        attrs[:stimulus_targets] = @targets.dup unless @targets.empty?
        attrs[:stimulus_values] = @values.dup unless @values.empty?
        attrs[:stimulus_values_from_props] = @values_from_props.dup unless @values_from_props.empty?
        attrs[:stimulus_classes] = @classes.dup unless @classes.empty?
        attrs[:stimulus_outlets] = @outlets.dup unless @outlets.empty?
        attrs
      end

      def to_hash
        to_attributes
      end
      alias_method :to_h, :to_hash
    end

    class_methods do
      def stimulus(&block)
        # Initialize stimulus builder if not already present
        if @stimulus_builder.nil?
          @stimulus_builder = StimulusBuilder.new
          @inheritance_merged = false
        end
        
        # Merge with parent class attributes only once per class
        if !@inheritance_merged && superclass.respond_to?(:stimulus_dsl_attributes)
          parent_attrs = superclass.stimulus_dsl_attributes
          unless parent_attrs.empty?
            # Merge parent attributes into current builder
            @stimulus_builder.instance_variable_get(:@actions).concat(parent_attrs[:stimulus_actions] || [])
            @stimulus_builder.instance_variable_get(:@targets).concat(parent_attrs[:stimulus_targets] || [])
            @stimulus_builder.instance_variable_get(:@values).merge!(parent_attrs[:stimulus_values] || {})
            @stimulus_builder.instance_variable_get(:@values_from_props).concat(parent_attrs[:stimulus_values_from_props] || [])
            @stimulus_builder.instance_variable_get(:@classes).merge!(parent_attrs[:stimulus_classes] || {})
            @stimulus_builder.instance_variable_get(:@outlets).merge!(parent_attrs[:stimulus_outlets] || {})
          end
          @inheritance_merged = true
        end
        
        # Execute the new block to add/merge new attributes
        @stimulus_builder.instance_eval(&block)
      end

      def stimulus_dsl_attributes
        # If no stimulus blocks have been defined on this class, check parent
        if @stimulus_builder.nil? && superclass.respond_to?(:stimulus_dsl_attributes)
          return superclass.stimulus_dsl_attributes
        end
        
        @stimulus_builder&.to_attributes || {}
      end
    end

    # Instance method to resolve prop-mapped values at runtime
    def resolve_values_from_props(prop_names)
      return {} if prop_names.empty?

      resolved = {}
      prop_names.each do |name|
        # Map from instance variable if it exists
        if instance_variable_defined?("@#{name}")
          resolved[name] = instance_variable_get("@#{name}")
        end
      end
      resolved
    end
  end
end