# frozen_string_literal: true

module Vident
  module Capabilities
    module RootElementRendering
      def root_element_attributes = {}

      def root_element_classes
        nil
      end

      def root_element(**overrides, &block)
        raise NoMethodError, "subclass must implement root_element"
      end

      # Dispatches to the adapter-specific `root_element` on subclasses
      # (Phlex / ViewComponent). Keep as `def` not `alias_method` so Ruby's
      # dynamic dispatch finds the subclass override.
      def root(...)
        root_element(...)
      end

      private

      def root_element_tag_type
        tag = resolved_root_element_attributes[:element_tag] || @element_tag
        tag.presence&.to_sym || :div
      end
    end
  end
end
