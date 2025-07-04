# frozen_string_literal: true

module Vident
  module TagHelper
    # Generate a tag with the given name and options, including stimulus data attributes
    def tag(
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
      # Ensure the plural attributes are actually enumerables
      tag_attribute_must_be_collection!(stimulus_controllers, "stimulus_controllers")
      tag_attribute_must_be_collection!(stimulus_targets, "stimulus_targets")
      tag_attribute_must_be_collection!(stimulus_actions, "stimulus_actions")
      tag_attribute_must_be_collection!(stimulus_outlets, "stimulus_outlets")
      tag_attribute_must_be_collection!(stimulus_values, "stimulus_values")
      tag_attribute_must_be_collection!(stimulus_classes, "stimulus_classes")

      stimulus_controllers_collection = send(:stimulus_controllers, *tag_wrap_single_stimulus_attribute(stimulus_controllers, stimulus_controller))
      stimulus_targets_collection = send(:stimulus_targets, *tag_wrap_single_stimulus_attribute(stimulus_targets, stimulus_target))
      stimulus_actions_collection = send(:stimulus_actions, *tag_wrap_single_stimulus_attribute(stimulus_actions, stimulus_action))
      stimulus_outlets_collection = send(:stimulus_outlets, *tag_wrap_single_stimulus_attribute(stimulus_outlets, stimulus_outlet))
      stimulus_values_collection = wrap_stimulus_values(tag_wrap_single_stimulus_attribute(stimulus_values, stimulus_value))
      stimulus_classes_collection = wrap_stimulus_classes(stimulus_classes || stimulus_class)

      stimulus_data_attributes = StimulusDataAttributeBuilder.new(
        controllers: stimulus_controllers_collection,
        actions: stimulus_actions_collection,
        targets: stimulus_targets_collection,
        outlets: stimulus_outlets_collection,
        values: stimulus_values_collection,
        classes: stimulus_classes_collection
      ).build
      generate_tag(tag_name, stimulus_data_attributes, options, &block)
    end

    private

    def tag_attribute_must_be_collection!(collection, name)
      return unless collection
      raise ArgumentError, "'#{name}:' must be an enumerable. Did you mean '#{name.to_s.singularize}:'?" unless collection.is_a?(Enumerable)
    end

    def tag_wrap_single_stimulus_attribute(plural, singular)
      plural || (singular ? Array.wrap(singular) : nil)
    end

    def generate_tag(tag_name, stimulus_data_attributes, options, &block)
      raise NoMethodError, "Not implemented"
    end
  end
end
