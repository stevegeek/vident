require "test_helper"

module Vident
  class StimulusTargetCollectionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
      @target1 = StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      @target2 = StimulusTarget.new(:other_target, implied_controller: @implied_controller)
      @target3 = StimulusTarget.new("custom_controller", :custom_target, implied_controller: @implied_controller)
    end

    def test_initialization_with_no_arguments
      collection = StimulusTargetCollection.new
      assert collection.empty?
      assert_equal({}, collection.to_h)
    end

    def test_initialization_with_single_target
      collection = StimulusTargetCollection.new(@target1)
      refute collection.empty?
      assert_equal({ "foo--my-controller-target" => "myTarget" }, collection.to_h)
    end

    def test_initialization_with_array_of_targets
      collection = StimulusTargetCollection.new([@target1, @target2])
      refute collection.empty?
      assert_equal({ "foo--my-controller-target" => "myTarget otherTarget" }, collection.to_h)
    end

    def test_initialization_with_nested_arrays
      collection = StimulusTargetCollection.new([[@target1, @target2], @target3])
      expected = { 
        "foo--my-controller-target" => "myTarget otherTarget",
        "custom-controller-target" => "customTarget"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_filters_out_nils
      collection = StimulusTargetCollection.new([@target1, nil, @target2])
      assert_equal({ "foo--my-controller-target" => "myTarget otherTarget" }, collection.to_h)
    end

    def test_append_operator
      collection = StimulusTargetCollection.new
      collection << @target1
      collection << @target2
      
      refute collection.empty?
      assert collection.any?
      assert_equal({ "foo--my-controller-target" => "myTarget otherTarget" }, collection.to_h)
    end

    def test_append_operator_returns_self
      collection = StimulusTargetCollection.new
      result = collection << @target1
      assert_same collection, result
    end

    def test_to_h_with_empty_collection
      collection = StimulusTargetCollection.new
      assert_equal({}, collection.to_h)
    end

    def test_to_h_merges_targets_with_same_attribute_name
      # Create targets that will have the same data attribute name
      target1 = StimulusTarget.new(:first, implied_controller: @implied_controller)
      target2 = StimulusTarget.new(:second, implied_controller: @implied_controller)
      target3 = StimulusTarget.new(:third, implied_controller: @implied_controller)
      
      collection = StimulusTargetCollection.new([target1, target2, target3])
      
      # All should merge under the same attribute name
      assert_equal({ "foo--my-controller-target" => "first second third" }, collection.to_h)
    end

    def test_to_h_keeps_separate_controller_targets
      # Create targets for different controllers
      target_main = StimulusTarget.new(:main_target, implied_controller: @implied_controller)
      target_custom = StimulusTarget.new("other_controller", :custom_target, implied_controller: @implied_controller)
      
      collection = StimulusTargetCollection.new([target_main, target_custom])
      
      expected = {
        "foo--my-controller-target" => "mainTarget",
        "other-controller-target" => "customTarget"
      }
      assert_equal expected, collection.to_h
    end

    def test_to_hash_alias
      collection = StimulusTargetCollection.new(@target1)
      assert_equal collection.to_h, collection.to_hash
    end

    def test_merge_with_empty_collection
      collection1 = StimulusTargetCollection.new(@target1)
      collection2 = StimulusTargetCollection.new
      
      merged = collection1.merge(collection2)
      
      refute_same collection1, merged
      assert_equal({ "foo--my-controller-target" => "myTarget" }, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      collection1 = StimulusTargetCollection.new(@target1)
      collection2 = StimulusTargetCollection.new(@target2)
      
      merged = collection1.merge(collection2)
      
      refute_same collection1, merged
      assert_equal({ "foo--my-controller-target" => "myTarget otherTarget" }, merged.to_h)
    end

    def test_merge_with_multiple_collections
      collection1 = StimulusTargetCollection.new(@target1)
      collection2 = StimulusTargetCollection.new(@target2)
      collection3 = StimulusTargetCollection.new(@target3)
      
      merged = collection1.merge(collection2, collection3)
      
      refute_same collection1, merged
      expected = { 
        "foo--my-controller-target" => "myTarget otherTarget",
        "custom-controller-target" => "customTarget"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_preserves_original_collections
      collection1 = StimulusTargetCollection.new(@target1)
      collection2 = StimulusTargetCollection.new(@target2)
      
      merged = collection1.merge(collection2)
      
      # Originals should be unchanged
      assert_equal({ "foo--my-controller-target" => "myTarget" }, collection1.to_h)
      assert_equal({ "foo--my-controller-target" => "otherTarget" }, collection2.to_h)
      # Merged should have both
      assert_equal({ "foo--my-controller-target" => "myTarget otherTarget" }, merged.to_h)
    end

    def test_merge_combines_targets_with_same_attribute_names
      # Create targets that will result in same attribute names when merged
      target1 = StimulusTarget.new(:button, implied_controller: @implied_controller)
      target2 = StimulusTarget.new(:input, implied_controller: @implied_controller)
      
      collection1 = StimulusTargetCollection.new(target1)
      collection2 = StimulusTargetCollection.new(target2)
      
      merged = collection1.merge(collection2)
      
      # Should merge under the same controller's target attribute
      assert_equal({ "foo--my-controller-target" => "button input" }, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = StimulusTargetCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = StimulusTargetCollection.new(@target1)
      merged = StimulusTargetCollection.merge(collection)
      
      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = StimulusTargetCollection.new(@target1)
      collection2 = StimulusTargetCollection.new(@target2)
      collection3 = StimulusTargetCollection.new(@target3)
      
      merged = StimulusTargetCollection.merge(collection1, collection2, collection3)
      
      refute_same collection1, merged
      expected = { 
        "foo--my-controller-target" => "myTarget otherTarget",
        "custom-controller-target" => "customTarget"
      }
      assert_equal expected, merged.to_h
    end

    def test_complex_real_world_scenario
      # Test with various target types for different controllers
      form_target = StimulusTarget.new("forms/signup_controller", :form, implied_controller: @implied_controller)
      submit_target = StimulusTarget.new("forms/signup_controller", :submit_button, implied_controller: @implied_controller)
      error_target = StimulusTarget.new("validation/error_controller", :error_container, implied_controller: @implied_controller)
      success_target = StimulusTarget.new("ui/feedback_controller", :success_message, implied_controller: @implied_controller)
      
      collection = StimulusTargetCollection.new([
        form_target,
        submit_target,
        error_target,
        success_target
      ])
      
      expected = { 
        "forms--signup-controller-target" => "form submitButton",
        "validation--error-controller-target" => "errorContainer",
        "ui--feedback-controller-target" => "successMessage"
      }
      assert_equal expected, collection.to_h
    end

    def test_merge_with_complex_targets_from_different_controllers
      # Create collections with targets from different controllers
      collection1 = StimulusTargetCollection.new([
        StimulusTarget.new("admin/users_controller", :user_list, implied_controller: @implied_controller),
        StimulusTarget.new("admin/users_controller", :search_input, implied_controller: @implied_controller)
      ])
      
      collection2 = StimulusTargetCollection.new([
        StimulusTarget.new("ui/modal_controller", :modal_dialog, implied_controller: @implied_controller),
        StimulusTarget.new("admin/users_controller", :filter_dropdown, implied_controller: @implied_controller)
      ])
      
      merged = collection1.merge(collection2)
      
      expected = {
        "admin--users-controller-target" => "userList searchInput filterDropdown",
        "ui--modal-controller-target" => "modalDialog"
      }
      assert_equal expected, merged.to_h
    end

    def test_inheritance_from_stimulus_collection_base
      collection = StimulusTargetCollection.new
      assert_kind_of StimulusCollectionBase, collection
    end

    def test_duplicate_targets_are_preserved
      # Duplicate targets should be preserved (no deduplication)
      collection = StimulusTargetCollection.new([@target1, @target1, @target2])
      assert_equal({ "foo--my-controller-target" => "myTarget myTarget otherTarget" }, collection.to_h)
    end

    def test_targets_with_special_characters_and_naming
      # Test snake_case to camelCase conversion
      snake_target = StimulusTarget.new(:error_message_container, implied_controller: @implied_controller)
      nested_target = StimulusTarget.new("admin/users_controller", :user_profile_form, implied_controller: @implied_controller)
      special_target = StimulusTarget.new(:submit_button_element, implied_controller: @implied_controller)
      
      collection = StimulusTargetCollection.new([
        snake_target,
        nested_target,
        special_target
      ])
      
      expected = {
        "foo--my-controller-target" => "errorMessageContainer submitButtonElement",
        "admin--users-controller-target" => "userProfileForm"
      }
      assert_equal expected, collection.to_h
    end

    def test_large_collection_performance
      # Test with a larger number of targets
      targets = 50.times.map do |i|
        StimulusTarget.new("target_#{i}".to_sym, implied_controller: @implied_controller)
      end
      
      collection = StimulusTargetCollection.new(targets)
      
      result = collection.to_h
      assert result.key?("foo--my-controller-target")
      
      target_names = result["foo--my-controller-target"].split(" ")
      assert_equal 50, target_names.length
      assert target_names.all? { |name| name.match?(/^target\d+$/) }
    end

    def test_merge_order_preservation
      # Test that merge preserves the order of targets
      target1 = StimulusTarget.new(:first, implied_controller: @implied_controller)
      target2 = StimulusTarget.new(:second, implied_controller: @implied_controller)
      target3 = StimulusTarget.new(:third, implied_controller: @implied_controller)
      
      collection1 = StimulusTargetCollection.new([target1, target2])
      collection2 = StimulusTargetCollection.new(target3)
      
      merged = collection1.merge(collection2)
      
      # Order should be preserved: first, second, third
      assert_equal({ "foo--my-controller-target" => "first second third" }, merged.to_h)
    end

    def test_complex_merging_with_overlapping_controller_names
      # Test merging when targets from same controllers are in different collections
      collection1 = StimulusTargetCollection.new([
        StimulusTarget.new("shared_controller", :target_a, implied_controller: @implied_controller),
        StimulusTarget.new("unique_controller_1", :target_b, implied_controller: @implied_controller)
      ])
      
      collection2 = StimulusTargetCollection.new([
        StimulusTarget.new("shared_controller", :target_c, implied_controller: @implied_controller),
        StimulusTarget.new("unique_controller_2", :target_d, implied_controller: @implied_controller)
      ])
      
      collection3 = StimulusTargetCollection.new([
        StimulusTarget.new("shared_controller", :target_e, implied_controller: @implied_controller)
      ])
      
      merged = StimulusTargetCollection.merge(collection1, collection2, collection3)
      
      expected = {
        "shared-controller-target" => "targetA targetC targetE",
        "unique-controller-1-target" => "targetB",
        "unique-controller-2-target" => "targetD"
      }
      assert_equal expected, merged.to_h
    end
  end
end