# frozen_string_literal: true

require "random/formatter"

module Vident
  class StableId
    class << self
      def set_current_sequence_generator
        ::Thread.current[:vident_number_sequence_generator] = id_sequence_generator
      end
      alias_method :new_current_sequence_generator, :set_current_sequence_generator

      def clear_current_sequence_generator
        ::Thread.current[:vident_number_sequence_generator] = nil
      end

      def next_id_in_sequence
        generator = ::Thread.current[:vident_number_sequence_generator]
        # When no generator exists, use a random value. This means we loose the stability of the ID sequence but
        # at least generate unique IDs for the current render.
        return Random.hex(16) unless generator
        generator.next.join("-")
      end

      private

      def id_sequence_generator
        number_generator = Random.new(42)
        Enumerator.produce { number_generator.hex(16) }.with_index
      end
    end
  end
end
