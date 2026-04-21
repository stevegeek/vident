# frozen_string_literal: true

require_relative "registry"

module Vident
  module Internals
    module AttributeWriter
      module_function

      def call(plan)
        Registry::KINDS.reduce({}) do |acc, kind|
          acc.merge(kind.value_class.to_data_hash(plan.public_send(kind.name)))
        end
      end
    end
  end
end
