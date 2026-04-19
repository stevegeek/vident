# frozen_string_literal: true

module Vident
  module Stimulus
    # Registry of primitive kinds. Add an entry (paired with a Value/Collection
    # class pair) to extend; plural parsers, mutators, and the data-attribute
    # builder pick it up. Array order = data attribute emission order.
    PRIMITIVES = [
      PositionalPrimitive.new(:controllers, StimulusController, StimulusControllerCollection),
      PositionalPrimitive.new(:actions, StimulusAction, StimulusActionCollection),
      PositionalPrimitive.new(:targets, StimulusTarget, StimulusTargetCollection),
      KeyedPrimitive.new(:outlets, StimulusOutlet, StimulusOutletCollection),
      KeyedPrimitive.new(:values, StimulusValue, StimulusValueCollection),
      KeyedPrimitive.new(:params, StimulusParam, StimulusParamCollection),
      KeyedPrimitive.new(:classes, StimulusClass, StimulusClassCollection)
    ].freeze

    PRIMITIVES_BY_NAME = PRIMITIVES.to_h { |primitive| [primitive.name, primitive] }.freeze

    class << self
      def primitive(name)
        PRIMITIVES_BY_NAME[name] or
          raise ArgumentError, "Unknown stimulus primitive #{name.inspect}; valid: #{PRIMITIVES_BY_NAME.keys.inspect}"
      end

      def each(&block) = PRIMITIVES.each(&block)

      def names = PRIMITIVES.map(&:name)
    end
  end
end
