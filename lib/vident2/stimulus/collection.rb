# frozen_string_literal: true

module Vident2
  module Stimulus
    # Tiny aggregation wrapper for the plural `stimulus_<kind>s` parsers.
    # Parametric over `kind`: the kind decides the per-element combining
    # rule via its value class's `.to_data_hash`. Users interact with
    # this object by splatting `{**component.stimulus_targets(...)}` into
    # a `data:` option on a tag, so `#to_h` is the single required shape.
    class Collection
      include Enumerable

      attr_reader :kind, :items

      def initialize(kind:, items:)
        @kind = kind
        @items = items.freeze
      end

      def each(&block) = @items.each(&block)
      def to_a = @items.dup
      def size = @items.size
      def length = @items.size
      def empty? = @items.empty?
      def any? = @items.any?

      # Delegates to the kind's `.to_data_hash` — same path AttributeWriter
      # uses at render time.
      def to_h
        @kind.value_class.to_data_hash(@items)
      end
      alias_method :to_hash, :to_h

      def merge(other)
        unless other.is_a?(self.class) && other.kind == @kind
          raise ArgumentError, "Collection#merge: can only merge with same-kind Collection"
        end
        self.class.new(kind: @kind, items: @items + other.items)
      end
    end
  end
end
