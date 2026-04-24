# frozen_string_literal: true

require "literal"
require_relative "combinable"

module Vident
  module Stimulus
    # Shared frozen-value base for the Stimulus primitive value classes
    # (Action, Target, Controller, Outlet, Value, Param, ClassMap).
    # Provides `Combinable` (`with`, pattern-matching `deconstruct_keys`)
    # and a default `to_data_hash(items)` that subclasses override when
    # they need non-trivial collection semantics (space-join etc.).
    #
    # Subclasses still override `to_h` / `to_hash` per class — Literal
    # auto-generates a prop-hash `to_h` from the prop DSL that would
    # shadow any default here, so the data-attribute-shape override
    # must live on each concrete class.
    class Base < ::Literal::Data
      include Combinable

      def self.to_data_hash(items)
        items.to_h(&:to_data_pair)
      end
    end
  end
end
