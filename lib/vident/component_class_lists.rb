# frozen_string_literal: true

module Vident
  module ComponentClassLists
    # Generates the full list of HTML classes for the component
    def render_classes(root_element_html_class = nil) = class_list_builder(root_element_html_class).build

    # Getter for a stimulus classes list so can be used in view to set initial state on SSR
    # Returns a String of classes that can be used in a `class` attribute.
    def class_list_for_stimulus_classes(*names)
      class_list_builder.build(@stimulus_classes_collection&.to_a, stimulus_class_names: names) || ""
    end

    private

    # Get or create a class list builder instance
    # Automatically detects if Tailwind module is included and TailwindMerge gem is available
    def class_list_builder(root_element_html_class = nil)
      @class_list_builder ||= ClassListBuilder.new(
        tailwind_merger:,
        component_name:,
        root_element_attributes_classes: @root_element_attributes_classes,
        root_element_classes:,
        root_element_html_class:,
        additional_classes: @classes,
        html_class: @html_options&.fetch(:class, nil)
      )
    end
  end
end
