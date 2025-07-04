require "test_helper"

module Vident
  class StableIdTest < Minitest::Test
    def setup
      @stable_id = Vident::StableId
    end

    def test_next_id_in_sequence_without_generator
      @stable_id.clear_current_sequence_generator
      assert_match(/\A[\da-f]{32}\z/i, @stable_id.next_id_in_sequence)
    end

    def test_next_id_in_sequence_with_generator
      @stable_id.new_current_sequence_generator
      assert_match(/\A[\da-f]{32}-0\z/i, @stable_id.next_id_in_sequence)
      assert_match(/\A[\da-f]{32}-1\z/i, @stable_id.next_id_in_sequence)
    end
  end
end
