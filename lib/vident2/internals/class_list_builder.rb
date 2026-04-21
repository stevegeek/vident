# frozen_string_literal: true

require "set"

module Vident2
  module Internals
    # @api private
    # Root-element class-list builder. Implements the 6-tier precedence
    # cascade plus optional TailwindMerger dedup.
    #
    # Tiers (render order, left -> right):
    #   1. component_name — always first.
    #   2-5. Priority cascade (only the highest non-nil wins):
    #        root_element_classes (instance override) <
    #        root_element_attributes[:classes] <
    #        root_element(class:) from template <
    #        html_options[:class] from prop
    #   6. classes: prop — ALWAYS appended, even when tier 5 is present.
    #
    # Plus: per-kind StimulusClassMap entries whose name is in
    # `stimulus_class_names` are appended as CSS. Tailwind merge runs last
    # if the merger is passed.
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

        # Priority cascade: top-down, first non-nil wins.
        if html_options_class
          parts.concat(Array.wrap(html_options_class))
        elsif root_element_html_class
          parts.concat(Array.wrap(root_element_html_class))
        elsif root_element_attributes_classes
          parts.concat(Array.wrap(root_element_attributes_classes))
        elsif root_element_classes
          parts.concat(Array.wrap(root_element_classes))
        end

        # `classes:` prop: always appended, even when something in the
        # cascade already contributed.
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

      # Pick ClassMap entries whose `name` matches any of the requested
      # Symbols/Strings (dasherized to match the ClassMap's canonical form).
      def stimulus_class_css(class_maps, names)
        names_set = names.map { |n| n.to_s.dasherize }.to_set
        class_maps.select { |cm| names_set.include?(cm.name) }.map(&:css)
      end
    end
  end
end
