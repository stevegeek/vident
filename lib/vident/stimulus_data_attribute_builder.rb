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
      {
        **merged_controllers,
        **merged_actions,
        **merged_targets,
        **merged_outlets,
        **merged_values,
        **merged_classes
      }.transform_keys(&:to_s).compact
    end

    private

    def merged_controllers
      return {} if @controllers.empty?
      
      if @controllers.first.is_a?(StimulusControllerCollection)
        StimulusControllerCollection.merge(*@controllers).to_h
      else
        StimulusControllerCollection.new(@controllers).to_h
      end
    end

    def merged_actions
      return {} if @actions.empty?
      
      if @actions.first.is_a?(StimulusActionCollection)
        StimulusActionCollection.merge(*@actions).to_h
      else
        StimulusActionCollection.new(@actions).to_h
      end
    end

    def merged_targets
      return {} if @targets.empty?
      
      if @targets.first.is_a?(StimulusTargetCollection)
        StimulusTargetCollection.merge(*@targets).to_h
      else
        StimulusTargetCollection.new(@targets).to_h
      end
    end

    def merged_outlets
      return {} if @outlets.empty?
      
      if @outlets.first.is_a?(StimulusOutletCollection)
        StimulusOutletCollection.merge(*@outlets).to_h
      else
        StimulusOutletCollection.new(@outlets).to_h
      end
    end

    def merged_values
      return {} if @values.empty?
      
      if @values.first.is_a?(StimulusValueCollection)
        StimulusValueCollection.merge(*@values).to_h
      else
        StimulusValueCollection.new(@values).to_h
      end
    end

    def merged_classes
      return {} if @classes.empty?
      
      if @classes.first.is_a?(StimulusClassCollection)
        StimulusClassCollection.merge(*@classes).to_h
      else
        StimulusClassCollection.new(@classes).to_h
      end
    end
  end
end
