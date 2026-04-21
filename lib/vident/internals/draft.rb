# frozen_string_literal: true

require_relative "registry"
require_relative "plan"

module Vident
  module Internals
    # Per-instance mutable accumulator; seals into a frozen Plan once rendering begins.
    class Draft
      def initialize(**collections)
        @collections = Registry.names.to_h { |name| [name, []] }
        collections.each { |k, v| @collections[k] = v.dup if @collections.key?(k) }
        @sealed = false
      end

      Registry.each do |kind|
        define_method(kind.name) { @collections[kind.name] }

        define_method(:"add_#{kind.name}") do |value_or_values|
          raise_if_sealed!
          Array(value_or_values).each { |v| @collections[kind.name] << v }
          self
        end
      end

      def sealed? = @sealed

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
        raise ::Vident::StateError,
          "cannot modify stimulus attributes after rendering has begun"
      end
    end
  end
end
