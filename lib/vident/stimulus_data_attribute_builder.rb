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
      StimulusControllerCollection.merge(*@controllers).to_h
    end

    def merged_actions
      StimulusActionCollection.merge(*@actions).to_h
    end

    def merged_targets
      StimulusTargetCollection.merge(*@targets).to_h
    end

    def merged_outlets
      StimulusOutletCollection.merge(*@outlets).to_h
    end

    def merged_values
      StimulusValueCollection.merge(*@values).to_h
    end

    def merged_classes
      StimulusClassCollection.merge(*@classes).to_h
    end
  end
end