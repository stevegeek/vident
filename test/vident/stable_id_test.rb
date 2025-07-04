require "test_helper"

module Vident
  class StableIdTest < Minitest::Test
    def setup
      # Clean up any existing generator
      StableId.clear_current_sequence_generator
    end

    def teardown
      # Clean up after tests
      StableId.clear_current_sequence_generator
    end

    def test_next_id_in_sequence_with_no_generator_returns_random_hex
      # When no generator is set, should return a random hex
      id = StableId.next_id_in_sequence
      assert_match(/\A[a-f0-9]{32}\z/, id)
    end

    def test_next_id_in_sequence_with_generator_returns_stable_sequence
      StableId.set_current_sequence_generator
      
      # First ID should be predictable since we use a fixed seed
      id1 = StableId.next_id_in_sequence
      assert_match(/\A[a-f0-9]+-\d+\z/, id1)
      
      # Second ID should be different but follow the pattern
      id2 = StableId.next_id_in_sequence
      assert_match(/\A[a-f0-9]+-\d+\z/, id2)
      
      refute_equal id1, id2
    end


    def test_next_id_in_sequence_without_generator
      Vident::StableId.clear_current_sequence_generator
      assert_match(/\A[\da-f]{32}\z/i, Vident::StableId.next_id_in_sequence)
    end

    def test_next_id_in_sequence_with_generator
      Vident::StableId.new_current_sequence_generator
      assert_match(/\A[\da-f]{32}-0\z/i, Vident::StableId.next_id_in_sequence)
      assert_match(/\A[\da-f]{32}-1\z/i, Vident::StableId.next_id_in_sequence)
    end

    def test_set_current_sequence_generator_creates_thread_local_generator
      StableId.set_current_sequence_generator
      generator = Thread.current[:vident_number_sequence_generator]
      refute_nil generator
    end

    def test_new_current_sequence_generator_alias
      StableId.new_current_sequence_generator
      generator = Thread.current[:vident_number_sequence_generator]
      refute_nil generator
    end

    def test_clear_current_sequence_generator_removes_generator
      StableId.set_current_sequence_generator
      refute_nil Thread.current[:vident_number_sequence_generator]
      
      StableId.clear_current_sequence_generator
      assert_nil Thread.current[:vident_number_sequence_generator]
    end

    def test_stable_id_sequence_is_consistent_with_same_generator
      StableId.set_current_sequence_generator
      id1 = StableId.next_id_in_sequence
      id2 = StableId.next_id_in_sequence
      
      # Clear and recreate with same seed
      StableId.clear_current_sequence_generator
      StableId.set_current_sequence_generator
      id3 = StableId.next_id_in_sequence
      id4 = StableId.next_id_in_sequence
      
      # Same sequence should be generated
      assert_equal id1, id3
      assert_equal id2, id4
    end

    def test_thread_isolation
      # Set generator in main thread
      StableId.set_current_sequence_generator
      main_id = StableId.next_id_in_sequence
      
      # Check that other thread doesn't have generator
      other_thread_id = nil
      thread = Thread.new do
        other_thread_id = StableId.next_id_in_sequence
      end
      thread.join
      
      # Other thread should generate random ID (different pattern)
      refute_equal main_id, other_thread_id
      assert_match(/\A[a-f0-9]{32}\z/, other_thread_id) # Random hex pattern
    end
  end
end