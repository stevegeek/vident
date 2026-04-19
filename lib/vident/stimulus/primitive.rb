# frozen_string_literal: true

module Vident
  module Stimulus
    # A Stimulus primitive kind: name, plus the Value/Collection classes that
    # back it. Two concrete subclasses distinguish how the primitive behaves
    # when a Hash is passed to the plural parser:
    #
    #   - `Keyed`      — `{a: 1, b: 2}` expands to one value object per pair.
    #                    Used for values / params / classes / outlets.
    #   - `Positional` — `{...}` is a single-arg descriptor (e.g. Action's
    #                    `{event:, method:, ...}` short form).
    #                    Used for controllers / actions / targets.
    class Primitive < ::Data.define(:name, :value_class, :collection_class)
      # Short forms. `name` (Data field) is the plural — `:values`; `plural`
      # is an alias for symmetry with `singular`.
      alias_method :plural, :name
      def singular = name.to_s.singularize.to_sym

      # The primitive's key in Vident's attribute namespace. Used both as the
      # parser method name (`def stimulus_values(...)`) and as the hash key
      # in DSL attrs / component props / `root_element_attributes` — the same
      # Symbol serves all three roles.
      def key = :"stimulus_#{name}"
      def singular_key = :"stimulus_#{singular}"

      def keyed? = raise NotImplementedError
    end

    class KeyedPrimitive < Primitive
      def keyed? = true
    end

    class PositionalPrimitive < Primitive
      def keyed? = false
    end
  end
end
