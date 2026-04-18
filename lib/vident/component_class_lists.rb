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

    # Not memoised: the per-thread TailwindMerger is the only expensive piece
    # and it's already cached; the builder itself just copies a few ivars.
    # Memoising here would latch the first caller's `root_element_html_class:`.
    def class_list_builder(root_element_html_class = nil)
      ClassListBuilder.new(
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
