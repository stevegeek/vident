# frozen_string_literal: true

module Vident
  module Stimulus
    # Shared `with(**overrides)` combinator for the frozen value classes.
    # Mirrors Ruby's `Data.define#with` convention (which Literal::Data
    # doesn't ship) so callers can decorate a value object without
    # mutating it.
    module Combinable
      # Canonical Ruby Data-object hooks. The value classes override `to_h`
      # to serialise to their data-attribute shape; without this module,
      # `deconstruct_keys` would inherit that override and pattern-matching
      # (`case a; in {event:}`) would silently fail.
      def deconstruct_keys(keys)
        h = self.class.literal_properties.properties_index.each_with_object({}) do |(name, _), acc|
          acc[name.to_sym] = public_send(name)
        end
        keys ? h.slice(*keys) : h
      end

      def deconstruct
        deconstruct_keys(nil).values
      end

      def with(**overrides)
        self.class.new(**deconstruct_keys(nil).merge(overrides))
      end
    end
  end
end
