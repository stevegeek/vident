# frozen_string_literal: true

require_relative "../internals/attribute_writer"
require_relative "../internals/class_list_builder"

module Vident
  module Capabilities
    module StimulusDataEmitting
      private

      def resolved_root_element_attributes
        return @__vident_rea if defined?(@__vident_rea)
        value = root_element_attributes
        @__vident_rea = value.is_a?(Hash) ? value : {}
      end

      def build_root_element_attributes(overrides)
        plan = seal_draft
        data_attrs = ::Vident::Internals::AttributeWriter.call(plan)

        extra = resolved_root_element_attributes
        extra_html_options = extra[:html_options] || {}
        extra_class = extra[:classes]
        extra_id = extra[:id]
        extra_data = extra_html_options[:data] || {}

        # data precedence (low→high): Plan fragments → attrs html_options[:data]
        # → instance html_options[:data] → overrides[:data].
        merged_data = data_attrs.dup
        merged_data.merge!(symbolize_keys(extra_data))
        merged_data.merge!(symbolize_keys(@html_options[:data] || {}))
        merged_data.merge!(symbolize_keys(overrides[:data] || {}))

        class_list = ::Vident::Internals::ClassListBuilder.call(
          component_name: component_name,
          root_element_classes: root_element_classes,
          root_element_attributes_classes: extra_class,
          root_element_html_class: overrides[:class],
          html_options_class: @html_options[:class] || extra_html_options[:class],
          classes_prop: @classes,
          tailwind_merger: tailwind_merger
        )

        merged = {}
        merged.merge!(extra_html_options.except(:data, :class))
        merged.merge!(@html_options.except(:data, :class))
        merged.merge!(overrides.except(:data, :class))
        merged[:class] = class_list if class_list
        merged[:data] = merged_data unless merged_data.empty?
        merged[:id] ||= extra_id || id

        merged
      end

      # Intentionally NOT `hash.symbolize_keys` (ActiveSupport): that calls
      # `to_sym` on every key, including integers, and would raise on keys
      # that don't respond to `to_sym`. Here we convert only String keys and
      # leave anything else (Symbols already) untouched — safe for the
      # user-supplied `data:` hashes that reach this method.
      def symbolize_keys(hash)
        return {} unless hash.is_a?(Hash)
        hash.transform_keys { |k| k.is_a?(String) ? k.to_sym : k }
      end
    end
  end
end
