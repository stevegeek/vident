# frozen_string_literal: true

require_relative "../internals/registry"

module Vident
  module Capabilities
    # `as_stimulus_*` returns a ready-to-splat HTML data-attribute string for
    # the given stimulus declaration — usable from any rendering context
    # (ERB partials, Phlex templates, helpers, controller renderers).
    #
    # Unlike `child_element`, these helpers don't write to a buffer, so they
    # work even when called on a Phlex Vident component from outside its own
    # `view_template` lifecycle.
    module StimulusAttributeStrings
      ::Vident::Internals::Registry.each do |kind|
        define_method(:"as_stimulus_#{kind.singular_name}") do |*args|
          to_data_attribute_string(**send(:"stimulus_#{kind.singular_name}", *args).to_h)
        end

        define_method(:"as_stimulus_#{kind.plural_name}") do |*args|
          to_data_attribute_string(**send(:"stimulus_#{kind.plural_name}", *args).to_h)
        end

        alias_method :"as_#{kind.singular_name}", :"as_stimulus_#{kind.singular_name}"
      end

      private

      def to_data_attribute_string(**attributes)
        attributes.map { |key, value| "data-#{escape_attribute_name_for_html(key)}=\"#{escape_attribute_value_for_html(value)}\"" }
          .join(" ")
          .html_safe
      end

      def escape_attribute_name_for_html(name)
        name.to_s.gsub(/[^a-zA-Z0-9\-_]/, "").tr("_", "-")
      end

      def escape_attribute_value_for_html(value)
        value.to_s.gsub('"', "&quot;").gsub("'", "&#39;")
      end
    end
  end
end
