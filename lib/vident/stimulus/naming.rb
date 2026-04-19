# frozen_string_literal: true

module Vident
  module Stimulus
    # Vident's internal naming conventions for per-primitive wiring — the
    # `add_stimulus_<plural>` mutator method, the `@stimulus_<plural>` prop
    # ivar, and the `@stimulus_<plural>_collection` parsed-collection ivar.
    # Mixed in by the consumers that need these helpers. Kept off `Primitive`
    # so the primitive stays a clean domain value object and doesn't carry
    # the implementation details of its consumers.
    module Naming
      def mutator_method(primitive) = :"add_stimulus_#{primitive.name}"

      def prop_ivar(primitive) = :"@stimulus_#{primitive.name}"

      def collection_ivar(primitive) = :"@stimulus_#{primitive.name}_collection"
    end
  end
end
