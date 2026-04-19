# frozen_string_literal: true

module Vident
  module ChildElementHelper
    # Explicit kwargs (14 of them, 1 plural + 1 singular per primitive) are the
    # public API — keep them so call-sites get typo-checking and IDE support.
    # The body is registry-driven via `Stimulus::PRIMITIVES`.
    def child_element(
      tag_name,
      stimulus_controllers: nil,
      stimulus_targets: nil,
      stimulus_actions: nil,
      stimulus_outlets: nil,
      stimulus_values: nil,
      stimulus_params: nil,
      stimulus_classes: nil,
      stimulus_controller: nil,
      stimulus_target: nil,
      stimulus_action: nil,
      stimulus_outlet: nil,
      stimulus_value: nil,
      stimulus_param: nil,
      stimulus_class: nil,
      **options,
      &block
    )
      inputs = {
        controllers: [stimulus_controllers, stimulus_controller],
        actions: [stimulus_actions, stimulus_action],
        targets: [stimulus_targets, stimulus_target],
        outlets: [stimulus_outlets, stimulus_outlet],
        values: [stimulus_values, stimulus_value],
        params: [stimulus_params, stimulus_param],
        classes: [stimulus_classes, stimulus_class]
      }

      collections = Stimulus::PRIMITIVES.to_h do |primitive|
        plural, singular = inputs.fetch(primitive.name)
        child_element_attribute_must_be_collection!(plural, primitive.key.to_s)
        args = primitive.keyed? ? [plural || singular] : child_element_wrap_single_stimulus_attribute(plural, singular)
        [primitive.name, send(primitive.key, *Array.wrap(args))]
      end

      data_attrs = StimulusDataAttributeBuilder.new(**collections).build
      generate_child_element(tag_name, data_attrs, options, &block)
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
