# frozen_string_literal: true

require "set"

module Vident
  class ClassListBuilder
    CLASSNAME_SEPARATOR = " "

    def initialize(tailwind_merger: nil, component_class_name: nil, element_classes: nil, html_class: nil)
      @class_list = component_class_name ? [component_class_name] : []
      @class_list.concat(Array.wrap(element_classes)) if element_classes
      @class_list.concat(Array.wrap(html_class)) if html_class
      @class_list.compact!
      @tailwind_merger = tailwind_merger

      if @tailwind_merger && !defined?(::TailwindMerge::Merger)
        raise LoadError, "TailwindMerge gem is required when using tailwind_merger:. Add 'gem \"tailwind_merge\"' to your Gemfile."
      end
    end

    # Main method to build a final class list from multiple sources
    # @param class_lists [Array<String, Array, StimulusClass, nil>] Multiple class sources to merge
    # @param stimulus_class_names [Array<Symbol, String>] Optional names of stimulus classes to include
    # @return [String, nil] Final space-separated class string or nil if no classes
    def build(extra_classes = nil, stimulus_class_names: [])
      class_list = @class_list + Array.wrap(extra_classes).compact
      flattened_classes = flatten_and_normalize_classes(class_list, stimulus_class_names)
      return nil if flattened_classes.empty?

      deduplicated_classes = dedupe_classes(flattened_classes)
      return nil if deduplicated_classes.blank?

      class_string = deduplicated_classes.join(CLASSNAME_SEPARATOR)

      if @tailwind_merger
        dedupe_with_tailwind(class_string)
      else
        class_string
      end
    end

    private

    # Flatten and normalize all input class sources
    def flatten_and_normalize_classes(class_lists, stimulus_class_names)
      stimulus_class_names_set = stimulus_class_names.map { |name| name.to_s.dasherize }.to_set

      class_lists.compact.flat_map do |class_source|
        case class_source
        when String
          class_source.split(CLASSNAME_SEPARATOR).reject(&:empty?)
        when Array
          class_source.flat_map { |item| normalize_single_class_item(item, stimulus_class_names_set) }
        else
          normalize_single_class_item(class_source, stimulus_class_names_set)
        end
      end.compact
    end

    # Normalize a single class item (could be string, StimulusClass, object with to_s, etc.)
    def normalize_single_class_item(item, stimulus_class_names_set)
      return [] if item.blank?

      # Handle StimulusClass instances
      if stimulus_class_instance?(item)
        # Only include if the class name matches one of the requested names
        # If stimulus_class_names_set is empty, exclude all stimulus classes
        if stimulus_class_names_set.present? && stimulus_class_names_set.include?(item.class_name)
          class_value = item.to_s
          class_value.include?(CLASSNAME_SEPARATOR) ?
            class_value.split(CLASSNAME_SEPARATOR).reject(&:empty?) :
            [class_value]
        else
          []
        end
      else
        # Handle regular strings and other objects
        item_string = item.to_s
        item_string.include?(CLASSNAME_SEPARATOR) ?
          item_string.split(CLASSNAME_SEPARATOR).reject(&:empty?) :
          [item_string]
      end
    end

    # Check if an item is a StimulusClass instance
    def stimulus_class_instance?(item)
      item.respond_to?(:class_name) && item.respond_to?(:to_s)
    end

    # Deduplicate classes while preserving order (first occurrence wins)
    def dedupe_classes(class_array)
      class_array.reject(&:blank?).uniq
    end

    # Merge classes using Tailwind CSS merge
    def dedupe_with_tailwind(class_string)
      @tailwind_merger.merge(class_string)
    end
  end
end
