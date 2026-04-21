# frozen_string_literal: true

require "set"

module Vident
  module Internals
    # Builds the root element's CSS class list with a 6-tier precedence cascade.
    # Tiers (left-to-right): component_name, then the highest-priority non-nil of
    # root_element_classes / root_element_attributes[:classes] / root_element(class:) /
    # html_options[:class], then classes: prop (always appended), then stimulus class maps.
    module ClassListBuilder
      CLASSNAME_SEPARATOR = " "

      module_function

      def call(
        component_name: nil,
        root_element_classes: nil,
        root_element_attributes_classes: nil,
        root_element_html_class: nil,
        html_options_class: nil,
        classes_prop: nil,
        stimulus_classes: nil,
        stimulus_class_names: nil,
        tailwind_merger: nil
      )
        parts = []
        parts << component_name if component_name

        if html_options_class
          parts.concat(Array.wrap(html_options_class))
        elsif root_element_html_class
          parts.concat(Array.wrap(root_element_html_class))
        elsif root_element_attributes_classes
          parts.concat(Array.wrap(root_element_attributes_classes))
        elsif root_element_classes
          parts.concat(Array.wrap(root_element_classes))
        end

        parts.concat(Array.wrap(classes_prop)) if classes_prop

        parts.compact!

        if stimulus_classes && stimulus_class_names && !stimulus_class_names.empty?
          parts.concat(stimulus_class_css(stimulus_classes, stimulus_class_names))
        end

        flattened = parts.flat_map { |s| s.to_s.split(/\s+/) }.reject(&:empty?)
        deduped = flattened.uniq
        return nil if deduped.empty?

        joined = deduped.join(CLASSNAME_SEPARATOR)
        tailwind_merger ? tailwind_merger.merge(joined) : joined
      end

      def stimulus_class_css(class_maps, names)
        names_set = names.map { |n| n.to_s.dasherize }.to_set
        class_maps.select { |cm| names_set.include?(cm.name) }.map(&:css)
      end
    end
  end
end
