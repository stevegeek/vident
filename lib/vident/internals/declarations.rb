# frozen_string_literal: true

require_relative "declaration"

module Vident
  module Internals
    # Frozen per-class aggregate of raw `Declaration` entries from `stimulus do` blocks.
    # Keyed kinds use `[key, Declaration]` pairs so later same-key entries replace earlier ones;
    # positional kinds are flat arrays where later blocks append.
    class Declarations < Data.define(
      :controllers,
      :actions,
      :targets,
      :outlets,
      :values,
      :params,
      :class_maps,
      :values_from_props
    )
      EMPTY_ARRAY = [].freeze

      def self.empty = @empty ||= new(
        controllers: EMPTY_ARRAY,
        actions: EMPTY_ARRAY,
        targets: EMPTY_ARRAY,
        outlets: EMPTY_ARRAY,
        values: EMPTY_ARRAY,
        params: EMPTY_ARRAY,
        class_maps: EMPTY_ARRAY,
        values_from_props: EMPTY_ARRAY
      ).freeze

      def any?
        !controllers.empty? || !actions.empty? || !targets.empty? ||
          !outlets.empty? || !values.empty? || !params.empty? ||
          !class_maps.empty? || !values_from_props.empty?
      end

      def merge(other)
        self.class.new(
          controllers: concat_positional(controllers, other.controllers),
          actions: concat_positional(actions, other.actions),
          targets: concat_positional(targets, other.targets),
          outlets: merge_keyed(outlets, other.outlets),
          values: merge_keyed(values, other.values),
          params: merge_keyed(params, other.params),
          class_maps: merge_keyed(class_maps, other.class_maps),
          values_from_props: (values_from_props + other.values_from_props).uniq.freeze
        )
      end

      private

      def concat_positional(a, b) = (a + b).freeze

      def merge_keyed(a, b)
        merged = {}
        a.each { |(k, d)| merged[k] = d }
        b.each { |(k, d)| merged[k] = d }
        merged.to_a.freeze
      end
    end
  end
end
