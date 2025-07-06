# frozen_string_literal: true

module Vident
  module StimulusDSL
    extend ActiveSupport::Concern

    class StimulusBuilder
      def initialize
        @actions = []
        @targets = []
        @values = {}
        @classes = {}
        @outlets = []
      end

      def actions(*action_names)
        @actions.concat(action_names)
      end

      def targets(*target_names)
        @targets.concat(target_names)
      end

      def values(*value_names)
        if value_names.length == 1 && value_names.first.is_a?(Hash)
          # Hash format: values name: "default_value", other: "other_default"
          @values.merge!(value_names.first)
        else
          # Symbol format: values :name, :other (will be mapped from props with same names)
          value_names.each { |name| @values[name] = :auto_map_from_prop }
        end
      end

      def classes(**class_mappings)
        @classes.merge!(class_mappings)
      end

      def outlets(*outlet_names)
        @outlets.concat(outlet_names)
      end

      def to_attributes
        attrs = {}
        attrs[:stimulus_actions] = @actions unless @actions.empty?
        attrs[:stimulus_targets] = @targets unless @targets.empty?
        attrs[:stimulus_values] = resolve_values unless @values.empty?
        attrs[:stimulus_classes] = @classes unless @classes.empty?
        attrs[:stimulus_outlets] = @outlets unless @outlets.empty?
        attrs
      end

      private

      def resolve_values
        # Values marked as :auto_map_from_prop will be resolved at runtime
        @values
      end
    end

    class_methods do
      def stimulus(&block)
        @stimulus_builder = StimulusBuilder.new
        @stimulus_builder.instance_eval(&block)
      end

      def stimulus_dsl_attributes
        @stimulus_builder&.to_attributes || {}
      end
    end

    # Instance method to resolve auto-mapped values at runtime
    def resolve_stimulus_dsl_values(dsl_values)
      return {} if dsl_values.empty?

      resolved = {}
      dsl_values.each do |name, value|
        if value == :auto_map_from_prop
          # Auto-map from instance variable if it exists
          resolved[name] = instance_variable_get("@#{name}") if instance_variable_defined?("@#{name}")
        else
          resolved[name] = value
        end
      end
      resolved
    end
  end
end