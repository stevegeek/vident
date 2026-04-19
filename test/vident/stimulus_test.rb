require "test_helper"

module Vident
  class StimulusTest < Minitest::Test
    def test_primitive_returns_registered_entry
      assert_equal :actions, Stimulus.primitive(:actions).name
    end

    def test_primitive_raises_for_unknown_name
      assert_raises(ArgumentError, /Unknown stimulus primitive/) do
        Stimulus.primitive(:bogus)
      end
    end

    def test_names_lists_all_primitives
      assert_equal [:controllers, :actions, :targets, :outlets, :values, :params, :classes],
        Stimulus.names
    end

    def test_each_yields_each_primitive
      yielded = []
      Stimulus.each { |p| yielded << p.name }
      assert_equal Stimulus.names, yielded
    end
  end
end
