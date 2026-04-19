# frozen_string_literal: true

module Vident
  class StimulusDataAttributeBuilder
    def initialize(**collections_by_name)
      unknown = collections_by_name.keys - Stimulus.names
      raise ArgumentError, "Unknown stimulus primitive(s) #{unknown.inspect}" if unknown.any?

      @collections_by_name = collections_by_name.transform_values { |v| Array(v) }
    end

    def build
      Stimulus::PRIMITIVES.each_with_object({}) do |primitive, attrs|
        attrs.merge!(merge_collection(primitive.collection_class, @collections_by_name[primitive.name] || []))
      end.transform_keys(&:to_s).compact
    end

    private

    # Items are either pre-built collections (DSL / resolver path) or raw value
    # objects (child_element path). Merge-or-wrap accordingly.
    def merge_collection(collection_class, items)
      return {} if items.empty?

      if items.first.is_a?(collection_class)
        collection_class.merge(*items).to_h
      else
        collection_class.new(items).to_h
      end
    end
  end
end
