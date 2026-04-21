# frozen_string_literal: true

require_relative "registry"
require_relative "plan"

module Vident2
  module Internals
    # @api private
    # Per-instance mutable working copy. Seven Arrays, one per Registry
    # kind. `add_<kind>(value_or_values)` mutators are the single sanctioned
    # seam for cross-instance mutation (outlet-host pattern) and for
    # `add_stimulus_*` calls from `after_component_initialize`.
    #
    # After `seal!` the Draft is closed — any further `add_*` raises
    # `Vident2::StateError`. The sealed Plan is a frozen Data.define snapshot.
    class Draft
      def initialize(**collections)
        @collections = Registry.names.to_h { |name| [name, []] }
        collections.each { |k, v| @collections[k] = v.dup if @collections.key?(k) }
        @sealed = false
      end

      Registry.each do |kind|
        # reader
        define_method(kind.name) { @collections[kind.name] }

        # mutator: one call = one logical add. Array input concats all
        # elements as pre-parsed values; a single non-Array value appends
        # as one entry.
        define_method(:"add_#{kind.name}") do |value_or_values|
          raise_if_sealed!
          Array(value_or_values).each { |v| @collections[kind.name] << v }
          self
        end
      end

      def sealed? = @sealed

      # Freeze the working copy and snapshot as a frozen Plan. Idempotent:
      # subsequent calls return the memoised Plan.
      def seal!
        return @plan if @sealed
        @sealed = true
        @collections.each_value(&:freeze)
        @collections.freeze
        @plan = Plan.new(**@collections)
      end

      def plan = seal!

      private

      def raise_if_sealed!
        return unless @sealed
        raise ::Vident2::StateError,
          "cannot modify stimulus attributes after rendering has begun"
      end
    end
  end
end
