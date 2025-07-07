require "test_helper"

module Vident
  class StimulusValueTest < Minitest::Test
    def setup
      @implied_controller = StimulusController.new("foo/my_controller")
    end

    def test_two_arguments_with_symbol_and_string
      value = StimulusValue.new(:url, "https://example.com", implied_controller: @implied_controller)
      assert_equal "https://example.com", value.to_s
      assert_equal "foo--my-controller", value.controller
      assert_equal "url", value.value_name
      assert_equal "https://example.com", value.value
      assert_equal "foo--my-controller-url-value", value.data_attribute_name
      assert_equal "https://example.com", value.data_attribute_value
    end

    def test_two_arguments_with_symbol_and_number
      value = StimulusValue.new(:count, 42, implied_controller: @implied_controller)
      assert_equal "42", value.to_s
      assert_equal "foo--my-controller", value.controller
      assert_equal "count", value.value_name
      assert_equal "42", value.value
    end

    def test_two_arguments_with_symbol_and_boolean
      value = StimulusValue.new(:enabled, true, implied_controller: @implied_controller)
      assert_equal "true", value.to_s
      assert_equal "foo--my-controller", value.controller
      assert_equal "enabled", value.value_name
      assert_equal "true", value.value
    end

    def test_two_arguments_with_symbol_and_array
      value = StimulusValue.new(:items, ["a", "b", "c"], implied_controller: @implied_controller)
      assert_equal '["a","b","c"]', value.to_s
      assert_equal "foo--my-controller", value.controller
      assert_equal "items", value.value_name
      assert_equal '["a","b","c"]', value.value
    end

    def test_two_arguments_with_symbol_and_hash
      value = StimulusValue.new(:config, {key: "value"}, implied_controller: @implied_controller)
      assert_equal '{"key":"value"}', value.to_s
      assert_equal "foo--my-controller", value.controller
      assert_equal "config", value.value_name
      assert_equal '{"key":"value"}', value.value
    end

    def test_three_arguments_with_controller_path
      value = StimulusValue.new("path/to/controller", :url, "https://example.com", implied_controller: @implied_controller)
      assert_equal "https://example.com", value.to_s
      assert_equal "path--to--controller", value.controller
      assert_equal "url", value.value_name
      assert_equal "https://example.com", value.value
      assert_equal "path--to--controller-url-value", value.data_attribute_name
      assert_equal "https://example.com", value.data_attribute_value
    end

    def test_snake_case_to_kebab_case_conversion
      value = StimulusValue.new(:user_name, "John", implied_controller: @implied_controller)
      assert_equal "user-name", value.value_name
      assert_equal "foo--my-controller-user-name-value", value.data_attribute_name
    end

    def test_to_h
      value = StimulusValue.new(:url, "https://example.com", implied_controller: @implied_controller)
      expected_hash = {"foo--my-controller-url-value" => "https://example.com"}
      assert_equal expected_hash, value.to_h
    end

    def test_inspect
      value = StimulusValue.new(:url, "https://example.com", implied_controller: @implied_controller)
      inspect_result = value.inspect
      assert_includes inspect_result, '#<Vident::StimulusValue'
      assert_includes inspect_result, '"foo--my-controller-url-value"'
      assert_includes inspect_result, '"https://example.com"'
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusValue.new(:url, implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusValue.new(:a, :b, :c, :d, implied_controller: @implied_controller)
      end
    end

    def test_invalid_argument_types
      assert_raises(ArgumentError) do
        StimulusValue.new(123, "value", implied_controller: @implied_controller)
      end
    end
  end
end
