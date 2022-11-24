# frozen_string_literal: true

module Vident
  class StableId
    class << self
      def set_current_sequence_generator
        ::Thread.current[:vident_number_sequence_generator] = id_sequence_generator
      end

      def next_id_in_sequence
        generator = ::Thread.current[:vident_number_sequence_generator]
        return "?" unless generator
        generator.next.join("-")
      end

      private

      def id_sequence_generator
        number_generator = Random.new(296_865_628_524)
        Enumerator.produce { number_generator.rand(10_000_000) }.with_index
      end
    end
  end
end
