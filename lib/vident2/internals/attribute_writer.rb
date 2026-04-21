# frozen_string_literal: true

require_relative "registry"

module Vident2
  module Internals
    # @api private
    # Pure: `Plan -> Hash{Symbol => String}` of `data-*` fragments.
    # Delegates per-kind combining (space-join, grouped-by-controller,
    # one-per-key) to each value class's `.to_data_hash`.
    module AttributeWriter
      module_function

      def call(plan)
        Registry::KINDS.each_with_object({}) do |kind, acc|
          fragment = kind.value_class.to_data_hash(plan.public_send(kind.name))
          acc.merge!(fragment)
        end
      end
    end
  end
end
