require "test_helper"

module Vident
  class StimulusNullTest < Minitest::Test
    def test_inspect_identifies_the_sentinel
      assert_equal "Vident::StimulusNull", StimulusNull.inspect
    end

    def test_to_s_emits_the_literal_null_string
      assert_equal "null", StimulusNull.to_s
    end

    def test_sentinel_is_frozen
      assert_predicate StimulusNull, :frozen?
    end
  end
end
