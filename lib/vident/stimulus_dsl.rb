# frozen_string_literal: true

module Vident
  module StimulusDSL
    extend ActiveSupport::Concern

    class_methods do
      def stimulus(&block)
        # Initialize stimulus builder if not already present
        if @stimulus_builder.nil?
          @stimulus_builder = StimulusBuilder.new
          @inheritance_merged = false
        end

        # Ensure inheritance is applied
        ensure_inheritance_merged

        # Execute the new block to add/merge new attributes
        @stimulus_builder.instance_eval(&block)
      end

      def stimulus_dsl_attributes(component_instance)
        # If no stimulus blocks have been defined on this class, check parent
        if @stimulus_builder.nil? && superclass.respond_to?(:stimulus_dsl_attributes)
          return superclass.stimulus_dsl_attributes(component_instance)
        end

        # Ensure inheritance is applied at access time
        ensure_inheritance_merged

        @stimulus_builder&.to_attributes(component_instance) || {}
      end

      private

      def ensure_inheritance_merged
        return if @inheritance_merged || @stimulus_builder.nil?

        if superclass.respond_to?(:stimulus_dsl_builder, true)
          parent_builder = superclass.send(:stimulus_dsl_builder)
          if parent_builder
            @stimulus_builder.merge_with(parent_builder)
          end
        end
        @inheritance_merged = true
      end

      protected

      def stimulus_dsl_builder
        @stimulus_builder
      end
    end

    # Instance method to get DSL attributes for this component instance
    def stimulus_dsl_attributes
      self.class.stimulus_dsl_attributes(self)
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
