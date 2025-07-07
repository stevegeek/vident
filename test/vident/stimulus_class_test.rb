require "test_helper"

module Vident
  class StimulusClassTest < Minitest::Test
    def setup
      @implied_controller = StimulusController.new("foo/my_controller")
    end

    def test_two_arguments_with_symbol_and_string
      css_class = StimulusClass.new(:loading, "spinner active", implied_controller: @implied_controller)
      assert_equal "spinner active", css_class.to_s
      assert_equal "foo--my-controller", css_class.controller
      assert_equal "loading", css_class.class_name
      assert_equal ["spinner", "active"], css_class.css_classes
      assert_equal "foo--my-controller-loading-class", css_class.data_attribute_name
      assert_equal "spinner active", css_class.data_attribute_value
    end

    def test_two_arguments_with_symbol_and_array
      css_class = StimulusClass.new(:loading, ["spinner", "active"], implied_controller: @implied_controller)
      assert_equal "spinner active", css_class.to_s
      assert_equal "foo--my-controller", css_class.controller
      assert_equal "loading", css_class.class_name
      assert_equal ["spinner", "active"], css_class.css_classes
      assert_equal "foo--my-controller-loading-class", css_class.data_attribute_name
      assert_equal "spinner active", css_class.data_attribute_value
    end

    def test_three_arguments_with_controller_path
      css_class = StimulusClass.new("path/to/controller", :loading, "spinner active", implied_controller: @implied_controller)
      assert_equal "spinner active", css_class.to_s
      assert_equal "path--to--controller", css_class.controller
      assert_equal "loading", css_class.class_name
      assert_equal ["spinner", "active"], css_class.css_classes
      assert_equal "path--to--controller-loading-class", css_class.data_attribute_name
      assert_equal "spinner active", css_class.data_attribute_value
    end

    def test_snake_case_to_kebab_case_conversion
      css_class = StimulusClass.new(:no_results, "hidden", implied_controller: @implied_controller)
      assert_equal "no-results", css_class.class_name
      assert_equal "foo--my-controller-no-results-class", css_class.data_attribute_name
    end

    def test_empty_string_handling
      css_class = StimulusClass.new(:loading, "", implied_controller: @implied_controller)
      assert_equal "", css_class.to_s
      assert_equal [], css_class.css_classes
    end

    def test_whitespace_string_handling
      css_class = StimulusClass.new(:loading, "  spinner   active  ", implied_controller: @implied_controller)
      assert_equal "spinner active", css_class.to_s
      assert_equal ["spinner", "active"], css_class.css_classes
    end

    def test_array_with_empty_strings
      css_class = StimulusClass.new(:loading, ["spinner", "", "active"], implied_controller: @implied_controller)
      assert_equal "spinner active", css_class.to_s
      assert_equal ["spinner", "active"], css_class.css_classes
    end

    def test_to_h
      css_class = StimulusClass.new(:loading, "spinner active", implied_controller: @implied_controller)
      expected_hash = {"foo--my-controller-loading-class" => "spinner active"}
      assert_equal expected_hash, css_class.to_h
    end

    def test_inspect
      css_class = StimulusClass.new(:loading, "spinner active", implied_controller: @implied_controller)
      inspect_result = css_class.inspect
      assert_includes inspect_result, '#<Vident::StimulusClass'
      assert_includes inspect_result, '"foo--my-controller-loading-class"'
      assert_includes inspect_result, '"spinner active"'
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusClass.new(:loading, implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusClass.new(:a, :b, :c, :d, implied_controller: @implied_controller)
      end
    end

    def test_invalid_argument_types
      assert_raises(ArgumentError) do
        StimulusClass.new(123, "classes", implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusClass.new(:loading, 123, implied_controller: @implied_controller)
      end
    end
  end
end
