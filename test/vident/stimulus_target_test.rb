require "test_helper"

module Vident
  class StimulusTargetTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
    end

    def test_single_symbol_argument
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      assert_equal "myTarget", target.to_s
      assert_equal "foo--my-controller", target.controller
      assert_equal "myTarget", target.name
      assert_equal "foo--my-controller-target", target.data_attribute_name
      assert_equal "myTarget", target.data_attribute_value
    end

    def test_single_string_argument
      target = StimulusTarget.new("myTarget", implied_controller: @implied_controller)
      assert_equal "myTarget", target.to_s
      assert_equal "foo--my-controller", target.controller
      assert_equal "myTarget", target.name
    end

    def test_two_arguments
      target = StimulusTarget.new("path/to/controller", :my_target, implied_controller: @implied_controller)
      assert_equal "myTarget", target.to_s
      assert_equal "path--to--controller", target.controller
      assert_equal "myTarget", target.name
    end

    def test_to_h
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      expected_hash = {"foo--my-controller-target" => "myTarget"}
      assert_equal expected_hash, target.to_h
    end

    def test_inspect
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      inspect_result = target.inspect
      assert_includes inspect_result, '#<Vident::StimulusTarget'
      assert_includes inspect_result, '"foo--my-controller-target"'
      assert_includes inspect_result, '"myTarget"'
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusTarget.new(implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusTarget.new(:a, :b, :c, implied_controller: @implied_controller)
      end
    end

    def test_invalid_argument_types
      assert_raises(ArgumentError) do
        StimulusTarget.new(123, :target, implied_controller: @implied_controller)
      end
    end
  end
end
