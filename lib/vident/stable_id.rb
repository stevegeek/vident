# frozen_string_literal: true

require "random/formatter"
require "digest/md5"

module Vident
  class StableId
    class GeneratorNotSetError < ::Vident::ConfigurationError; end

    class StrategyNotConfiguredError < ::Vident::ConfigurationError; end

    RANDOM_FALLBACK = ->(generator) do
      return Random.hex(16) unless generator
      generator.next.join("-")
    end

    STRICT = ->(generator) do
      unless generator
        raise GeneratorNotSetError,
          "No Vident::StableId sequence generator is set on the current thread. " \
          "Call Vident::StableId.set_current_sequence_generator(seed: ...) in a " \
          "before_action (or wrap the render in StableId.with_sequence_generator)."
      end
      generator.next.join("-")
    end

    class << self
      # Callable(generator_or_nil) -> String. Host app must configure before first render.
      attr_accessor :strategy

      def set_current_sequence_generator(seed:)
        ::Thread.current[:vident_number_sequence_generator] = id_sequence_generator(seed)
      end

      def clear_current_sequence_generator
        ::Thread.current[:vident_number_sequence_generator] = nil
      end

      def with_sequence_generator(seed:)
        previous = ::Thread.current[:vident_number_sequence_generator]
        set_current_sequence_generator(seed: seed)
        yield
      ensure
        ::Thread.current[:vident_number_sequence_generator] = previous
      end

      def next_id_in_sequence
        unless @strategy
          raise StrategyNotConfiguredError,
            "Vident::StableId.strategy is not configured. Run " \
            "`bin/rails generate vident:install`, or set it manually in an " \
            "initializer (e.g. `Vident::StableId.strategy = Vident::StableId::STRICT`)."
        end
        @strategy.call(::Thread.current[:vident_number_sequence_generator])
      end

      private

      def id_sequence_generator(seed)
        raise ArgumentError, "seed: cannot be nil" if seed.nil?
        number_generator = Random.new(coerce_seed(seed))
        Enumerator.produce { number_generator.hex(16) }.with_index
      end

      def coerce_seed(seed)
        Digest::MD5.hexdigest(seed.to_s).to_i(16)
      end
    end
  end
end
