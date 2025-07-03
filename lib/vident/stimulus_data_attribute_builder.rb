# frozen_string_literal: true

module Vident
  # Builds a hash of Stimulus data attributes from collections of stimulus objects
  # Handles merging multiple actions, targets, outlets, values, and classes
  # into the final data-* attributes needed for HTML elements
  class StimulusDataAttributeBuilder
    def initialize(controllers: [], actions: [], targets: [], outlets: [], values: [], classes: [])
      @controllers = Array(controllers)
      @actions = Array(actions)
      @targets = Array(targets)
      @outlets = Array(outlets)
      @values = Array(values)
      @classes = Array(classes)
    end

    # Build the final data attributes hash
    def build
      data_attributes = {}

      # Add controllers
      if @controllers.any?
        controller_values = @controllers.map(&:to_s).reject(&:empty?)
        if controller_values.any?
          data_attributes[:controller] = controller_values.join(" ")
        end
      end

      # Add actions (space-separated in data-action)
      if @actions.any?
        data_attributes[:action] = @actions.map(&:to_s).join(" ")
      end

      # Add targets (merge targets with same attribute name)
      @targets.each do |target|
        target_hash = target.to_h
        target_hash.each do |key, value|
          if data_attributes.key?(key)
            # Merge space-separated values for same target attribute
            data_attributes[key] = "#{data_attributes[key]} #{value}"
          else
            data_attributes[key] = value
          end
        end
      end

      # Add outlets (each outlet gets its own data attribute)
      @outlets.each do |outlet|
        data_attributes.merge!(outlet.to_h)
      end

      # Add values (each value gets its own data attribute)
      @values.each do |value|
        data_attributes.merge!(value.to_h)
      end

      # Add classes (each class gets its own data attribute)
      @classes.each do |css_class|
        data_attributes.merge!(css_class.to_h)
      end

      # Convert symbol keys to strings for final output
      data_attributes.transform_keys(&:to_s).compact
    end
  end
end