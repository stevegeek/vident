require "test_helper"

module Vident
  class StimulusParamTest < Minitest::Test
    def setup
      @implied_controller = StimulusController.new("foo/my_controller")
    end

    def test_two_arguments_with_symbol_and_string
      param = StimulusParam.new(:kind, "promote", implied_controller: @implied_controller)
      assert_equal "promote", param.to_s
      assert_equal "foo--my-controller", param.controller
      assert_equal "kind", param.param_name
      assert_equal "promote", param.value
      assert_equal "foo--my-controller-kind-param", param.data_attribute_name
      assert_equal "promote", param.data_attribute_value
    end

    def test_two_arguments_with_symbol_and_number
      param = StimulusParam.new(:release_id, 42, implied_controller: @implied_controller)
      assert_equal "42", param.to_s
      assert_equal "release-id", param.param_name
      assert_equal "42", param.value
    end

    def test_two_arguments_with_symbol_and_boolean
      param = StimulusParam.new(:admin, true, implied_controller: @implied_controller)
      assert_equal "true", param.to_s
      assert_equal "admin", param.param_name
    end

    def test_two_arguments_with_symbol_and_array
      param = StimulusParam.new(:tags, ["ruby", "rails"], implied_controller: @implied_controller)
      assert_equal '["ruby","rails"]', param.to_s
    end

    def test_two_arguments_with_symbol_and_hash
      param = StimulusParam.new(:meta, {k: "v"}, implied_controller: @implied_controller)
      assert_equal '{"k":"v"}', param.to_s
    end

    def test_three_arguments_with_controller_path
      param = StimulusParam.new("admin/users", :scope, "full", implied_controller: @implied_controller)
      assert_equal "full", param.to_s
      assert_equal "admin--users", param.controller
      assert_equal "scope", param.param_name
      assert_equal "admin--users-scope-param", param.data_attribute_name
    end

    def test_snake_case_to_kebab_case_conversion
      param = StimulusParam.new(:release_id, 1, implied_controller: @implied_controller)
      assert_equal "release-id", param.param_name
      assert_equal "foo--my-controller-release-id-param", param.data_attribute_name
    end

    def test_to_h
      param = StimulusParam.new(:kind, "promote", implied_controller: @implied_controller)
      assert_equal({"foo--my-controller-kind-param" => "promote"}, param.to_h)
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusParam.new(:only_one, implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusParam.new(:a, :b, :c, :d, implied_controller: @implied_controller)
      end
    end

    def test_invalid_argument_types
      assert_raises(ArgumentError) do
        StimulusParam.new(123, "value", implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusParam.new(:sym, :sym, "value", implied_controller: @implied_controller)
      end
    end
  end
end
