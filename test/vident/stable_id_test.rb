require "test_helper"

module Vident
  class StableIdTest < Minitest::Test
    def setup
      @previous_strategy = StableId.strategy
      StableId.clear_current_sequence_generator
    end

    def teardown
      StableId.clear_current_sequence_generator
      StableId.strategy = @previous_strategy
    end

    def test_next_id_raises_when_strategy_not_configured
      StableId.strategy = nil
      assert_raises(StableId::StrategyNotConfiguredError) do
        StableId.next_id_in_sequence
      end
    end

    def test_random_fallback_returns_random_hex_when_no_generator
      StableId.strategy = StableId::RANDOM_FALLBACK
      id = StableId.next_id_in_sequence
      assert_match(/\A[a-f0-9]{32}\z/, id)
    end

    def test_random_fallback_uses_generator_when_set
      StableId.strategy = StableId::RANDOM_FALLBACK
      StableId.set_current_sequence_generator(seed: "test")
      assert_match(/\A[\da-f]{32}-0\z/i, StableId.next_id_in_sequence)
      assert_match(/\A[\da-f]{32}-1\z/i, StableId.next_id_in_sequence)
    end

    def test_strict_raises_when_no_generator
      StableId.strategy = StableId::STRICT
      assert_raises(StableId::GeneratorNotSetError) do
        StableId.next_id_in_sequence
      end
    end

    def test_strict_uses_generator_when_set
      StableId.strategy = StableId::STRICT
      StableId.set_current_sequence_generator(seed: "test")
      assert_match(/\A[\da-f]{32}-0\z/i, StableId.next_id_in_sequence)
      assert_match(/\A[\da-f]{32}-1\z/i, StableId.next_id_in_sequence)
    end

    def test_set_current_sequence_generator_requires_seed
      assert_raises(ArgumentError) do
        StableId.set_current_sequence_generator(seed: nil)
      end
      assert_raises(ArgumentError) do
        StableId.set_current_sequence_generator
      end
    end

    def test_same_seed_produces_same_sequence_across_requests
      StableId.strategy = StableId::STRICT

      StableId.set_current_sequence_generator(seed: "/foo")
      id1 = StableId.next_id_in_sequence
      id2 = StableId.next_id_in_sequence

      StableId.clear_current_sequence_generator
      StableId.set_current_sequence_generator(seed: "/foo")
      id3 = StableId.next_id_in_sequence
      id4 = StableId.next_id_in_sequence

      assert_equal id1, id3
      assert_equal id2, id4
    end

    def test_different_seeds_produce_different_sequences
      StableId.strategy = StableId::STRICT

      StableId.set_current_sequence_generator(seed: "/foo")
      foo_id = StableId.next_id_in_sequence

      StableId.clear_current_sequence_generator
      StableId.set_current_sequence_generator(seed: "/bar")
      bar_id = StableId.next_id_in_sequence

      refute_equal foo_id, bar_id
    end

    def test_seed_accepts_arbitrary_types
      StableId.strategy = StableId::STRICT
      [42, :symbol, "string", ["composite", 1]].each do |seed|
        StableId.set_current_sequence_generator(seed: seed)
        assert_match(/\A[\da-f]{32}-0\z/i, StableId.next_id_in_sequence)
        StableId.clear_current_sequence_generator
      end
    end

    def test_with_sequence_generator_scopes_generator_to_block
      StableId.strategy = StableId::STRICT

      ids = nil
      StableId.with_sequence_generator(seed: "scope") do
        ids = [StableId.next_id_in_sequence, StableId.next_id_in_sequence]
      end

      assert_equal 2, ids.length
      assert_nil ::Thread.current[:vident_number_sequence_generator]
    end

    def test_with_sequence_generator_restores_previous_generator
      StableId.strategy = StableId::STRICT

      StableId.set_current_sequence_generator(seed: "outer")
      outer_first = StableId.next_id_in_sequence

      StableId.with_sequence_generator(seed: "inner") do
        inner_id = StableId.next_id_in_sequence
        refute_match(outer_first, inner_id)
      end

      outer_second = StableId.next_id_in_sequence
      assert_match(/-1\z/, outer_second)
    end

    def test_with_sequence_generator_restores_live_outer_on_exception
      StableId.strategy = StableId::STRICT

      StableId.set_current_sequence_generator(seed: "outer")
      outer = ::Thread.current[:vident_number_sequence_generator]
      refute_nil outer, "precondition: outer generator must be set"

      assert_raises(RuntimeError) do
        StableId.with_sequence_generator(seed: "inner") do
          StableId.next_id_in_sequence
          raise "boom"
        end
      end

      assert_same outer, ::Thread.current[:vident_number_sequence_generator]
      # Index must still be 0: proves the inner block did not advance the outer enumerator.
      assert_match(/-0\z/, StableId.next_id_in_sequence)
    end

    def test_thread_isolation
      StableId.strategy = StableId::RANDOM_FALLBACK
      StableId.set_current_sequence_generator(seed: "main")
      main_id = StableId.next_id_in_sequence

      other_thread_id = nil
      Thread.new { other_thread_id = StableId.next_id_in_sequence }.join

      refute_equal main_id, other_thread_id
      assert_match(/\A[a-f0-9]{32}\z/, other_thread_id)
    end
  end
end
