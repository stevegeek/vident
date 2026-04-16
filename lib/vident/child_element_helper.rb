# frozen_string_literal: true

module Vident
  module ChildElementHelper
    def child_element(
      tag_name,
      stimulus_controllers: nil,
      stimulus_targets: nil,
      stimulus_actions: nil,
      stimulus_outlets: nil,
      stimulus_values: nil,
      stimulus_classes: nil,
      stimulus_controller: nil,
      stimulus_target: nil,
      stimulus_action: nil,
      stimulus_outlet: nil,
      stimulus_value: nil,
      stimulus_class: nil,
      **options,
      &block
    )
      child_element_attribute_must_be_collection!(stimulus_controllers, "stimulus_controllers")
      child_element_attribute_must_be_collection!(stimulus_targets, "stimulus_targets")
      child_element_attribute_must_be_collection!(stimulus_actions, "stimulus_actions")
      child_element_attribute_must_be_collection!(stimulus_outlets, "stimulus_outlets")
      child_element_attribute_must_be_collection!(stimulus_values, "stimulus_values")
      child_element_attribute_must_be_collection!(stimulus_classes, "stimulus_classes")

      stimulus_controllers_collection = send(:stimulus_controllers, *child_element_wrap_single_stimulus_attribute(stimulus_controllers, stimulus_controller))
      stimulus_targets_collection = send(:stimulus_targets, *child_element_wrap_single_stimulus_attribute(stimulus_targets, stimulus_target))
      stimulus_actions_collection = send(:stimulus_actions, *child_element_wrap_single_stimulus_attribute(stimulus_actions, stimulus_action))
      stimulus_outlets_collection = send(:stimulus_outlets, *child_element_wrap_single_stimulus_attribute(stimulus_outlets, stimulus_outlet))
      stimulus_values_collection = send(:stimulus_values, stimulus_values || stimulus_value)
      stimulus_classes_collection = send(:stimulus_classes, stimulus_classes || stimulus_class)

      stimulus_data_attributes = StimulusDataAttributeBuilder.new(
        controllers: stimulus_controllers_collection,
        actions: stimulus_actions_collection,
        targets: stimulus_targets_collection,
        outlets: stimulus_outlets_collection,
        values: stimulus_values_collection,
        classes: stimulus_classes_collection
      ).build
      generate_child_element(tag_name, stimulus_data_attributes, options, &block)
    end

    private

    def child_element_attribute_must_be_collection!(collection, name)
      return unless collection
      raise ArgumentError, "'#{name}:' must be an enumerable. Did you mean '#{name.to_s.singularize}:'?" unless collection.is_a?(Enumerable)
    end

    def child_element_wrap_single_stimulus_attribute(plural, singular)
      return plural if plural
      singular.nil? ? nil : [singular]
    end

    def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
      raise NoMethodError, "Not implemented"
    end
  end
end
