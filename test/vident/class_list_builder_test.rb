require "test_helper"

module Vident
  class ClassListBuilderTest < Minitest::Test
    def setup
      @builder = ClassListBuilder.new
      # Don't create @tailwind_builder in setup since TailwindMerge isn't available
    end

    def test_build_with_single_string
      result = @builder.build("btn primary")
      assert_equal "btn primary", result
    end

    def test_build_with_multiple_strings
      result = @builder.build(["btn primary", "large active"])
      assert_equal "btn primary large active", result
    end

    def test_build_with_arrays
      result = @builder.build([["btn", "primary"], ["large", "active"]])
      assert_equal "btn primary large active", result
    end

    def test_build_with_mixed_inputs
      result = @builder.build(["btn primary", ["large"], "active disabled"])
      assert_equal "btn primary large active disabled", result
    end

    def test_build_removes_duplicates
      result = @builder.build(["btn primary", "btn active", ["primary", "large"]])
      assert_equal "btn primary active large", result
    end

    def test_build_removes_blanks
      result = @builder.build(["btn  primary", ["", nil, "large"], "  "])
      assert_equal "btn primary large", result
    end

    def test_build_with_no_classes_returns_nil
      result = @builder.build(["", [], nil, "  "])
      assert_nil result
    end

    def test_build_with_nil_inputs
      result = @builder.build([nil, "btn", nil, "primary"])
      assert_equal "btn primary", result
    end

    def test_build_preserves_order_first_occurrence_wins
      result = @builder.build(["btn primary large", "btn small primary"])
      assert_equal "btn primary large small", result
    end

    def test_build_with_stimulus_classes_empty_cases
      # Test with empty stimulus classes
      result = @builder.build([], stimulus_class_names: [:loading])
      assert_nil result

      # Test with empty names (stimulus classes should be excluded)
      mock_stimulus_classes = [create_mock_stimulus_class("loading", "spinner active")]
      result = @builder.build(mock_stimulus_classes)
      assert_nil result
    end

    def test_build_with_stimulus_classes_single_match
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading", "spinner active"),
        create_mock_stimulus_class("error", "alert danger")
      ]
      
      result = @builder.build(mock_stimulus_classes, stimulus_class_names: [:loading])
      assert_equal "spinner active", result
    end

    def test_build_with_stimulus_classes_multiple_matches
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading", "spinner active"),
        create_mock_stimulus_class("error", "alert danger"),
        create_mock_stimulus_class("success", "notification green")
      ]
      
      result = @builder.build(mock_stimulus_classes, stimulus_class_names: [:loading, :error])
      assert_equal "spinner active alert danger", result
    end

    def test_build_with_stimulus_classes_with_underscores
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading-spinner", "spinner active"),
        create_mock_stimulus_class("error-message", "alert danger")
      ]
      
      # Test that underscore names are converted to dashes for matching
      result = @builder.build(mock_stimulus_classes, stimulus_class_names: [:loading_spinner, :error_message])
      assert_equal "spinner active alert danger", result
    end

    def test_build_with_stimulus_classes_with_duplicates
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading", "spinner active"),
        create_mock_stimulus_class("error", "spinner alert") # duplicate "spinner"
      ]
      
      result = @builder.build(mock_stimulus_classes, stimulus_class_names: [:loading, :error])
      assert_equal "spinner active alert", result
    end

    def test_build_with_stimulus_classes_non_existent_names
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading", "spinner active")
      ]
      
      result = @builder.build(mock_stimulus_classes, stimulus_class_names: [:nonexistent])
      assert_nil result
      
      # Mixed existing and non-existent
      result = @builder.build(mock_stimulus_classes, stimulus_class_names: [:loading, :nonexistent])
      assert_equal "spinner active", result
    end

    def test_build_with_mixed_strings_and_stimulus_classes
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading", "spinner active"),
        create_mock_stimulus_class("error", "alert danger")
      ]
      
      # Mix regular strings with stimulus classes
      result = @builder.build(["btn primary", mock_stimulus_classes, ["large"]], stimulus_class_names: [:loading])
      assert_equal "btn primary spinner active large", result
    end

    def test_build_with_stimulus_classes_no_matching_names
      mock_stimulus_classes = [
        create_mock_stimulus_class("loading", "spinner active"),
        create_mock_stimulus_class("error", "alert danger")
      ]
      
      # No matching names provided - stimulus classes should be excluded
      result = @builder.build(["btn primary", mock_stimulus_classes, "large"])
      assert_equal "btn primary large", result
    end

    def test_tailwind_integration_with_tailwind_gem
      # Since TailwindMerge is available in this test environment, test actual usage
      tailwind_builder = ClassListBuilder.new(tailwind_merger: TailwindMerge::Merger.new)
      
      # Test conflicting background classes - TailwindMerge should keep the last one
      result = tailwind_builder.build(["bg-red-500 text-white", "bg-blue-500 text-lg"])
      
      # Should have bg-blue-500 (last wins) but not bg-red-500
      assert_includes result, 'bg-blue-500'
      assert_includes result, 'text-white'
      assert_includes result, 'text-lg'
      refute_includes result, 'bg-red-500'
    end

    def test_tailwind_integration_without_tailwind_gem
      # Test that passing a non-TailwindMerge object when TailwindMerge is not available
      # should raise a LoadError
      fake_merger = Object.new
      
      # Mock the absence of TailwindMerge by temporarily removing it
      original_tailwind_merge = Object.const_get(:TailwindMerge) if Object.const_defined?(:TailwindMerge)
      Object.send(:remove_const, :TailwindMerge) if Object.const_defined?(:TailwindMerge)
      
      # Now it should raise an error when passing a merger without TailwindMerge available
      assert_raises(LoadError) do
        ClassListBuilder.new(tailwind_merger: fake_merger)
      end
    ensure
      # Restore TailwindMerge
      Object.const_set(:TailwindMerge, original_tailwind_merge) if original_tailwind_merge
    end

    def test_handles_objects_with_to_s
      object_with_to_s = Object.new
      def object_with_to_s.to_s
        "custom-class"
      end
      
      result = @builder.build(["btn", [object_with_to_s], "primary"])
      assert_equal "btn custom-class primary", result
    end

    def test_handles_nested_space_separated_strings_in_arrays
      result = @builder.build([["btn primary", "large"], ["active disabled"]])
      assert_equal "btn primary large active disabled", result
    end

    private

    def create_mock_stimulus_class(class_name, class_value)
      mock_class = Object.new
      
      def mock_class.class_name
        @class_name
      end
      
      def mock_class.to_s
        @class_value
      end
      
      def mock_class.set_values(class_name, class_value)
        @class_name = class_name
        @class_value = class_value
      end
      
      mock_class.set_values(class_name, class_value)
      mock_class
    end
  end
end