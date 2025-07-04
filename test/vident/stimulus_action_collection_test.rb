require "test_helper"

module Vident
  class StimulusActionCollectionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
      @action1 = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      @action2 = StimulusAction.new(:click, :other_action, implied_controller: @implied_controller)
      @action3 = StimulusAction.new("custom_controller", :custom_action, implied_controller: @implied_controller)
    end

    def test_initialization_with_no_arguments
      collection = StimulusActionCollection.new
      assert collection.empty?
      assert_equal({}, collection.to_h)
    end

    def test_initialization_with_single_action
      collection = StimulusActionCollection.new(@action1)
      refute collection.empty?
      assert_equal({action: "foo--my-controller#myAction"}, collection.to_h)
    end

    def test_initialization_with_array_of_actions
      collection = StimulusActionCollection.new([@action1, @action2])
      refute collection.empty?
      assert_equal({action: "foo--my-controller#myAction click->foo--my-controller#otherAction"}, collection.to_h)
    end

    def test_initialization_with_nested_arrays
      collection = StimulusActionCollection.new([[@action1, @action2], @action3])
      expected = {action: "foo--my-controller#myAction click->foo--my-controller#otherAction custom-controller#customAction"}
      assert_equal expected, collection.to_h
    end

    def test_initialization_filters_out_nils
      collection = StimulusActionCollection.new([@action1, nil, @action2])
      assert_equal({action: "foo--my-controller#myAction click->foo--my-controller#otherAction"}, collection.to_h)
    end

    def test_append_operator
      collection = StimulusActionCollection.new
      collection << @action1
      collection << @action2

      refute collection.empty?
      assert collection.any?
      assert_equal({action: "foo--my-controller#myAction click->foo--my-controller#otherAction"}, collection.to_h)
    end

    def test_append_operator_returns_self
      collection = StimulusActionCollection.new
      result = collection << @action1
      assert_same collection, result
    end

    def test_to_h_with_empty_collection
      collection = StimulusActionCollection.new
      assert_equal({}, collection.to_h)
    end

    def test_to_hash_alias
      collection = StimulusActionCollection.new(@action1)
      assert_equal collection.to_h, collection.to_hash
    end

    def test_merge_with_empty_collection
      collection1 = StimulusActionCollection.new(@action1)
      collection2 = StimulusActionCollection.new

      merged = collection1.merge(collection2)

      refute_same collection1, merged
      assert_equal({action: "foo--my-controller#myAction"}, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      collection1 = StimulusActionCollection.new(@action1)
      collection2 = StimulusActionCollection.new(@action2)

      merged = collection1.merge(collection2)

      refute_same collection1, merged
      assert_equal({action: "foo--my-controller#myAction click->foo--my-controller#otherAction"}, merged.to_h)
    end

    def test_merge_with_multiple_collections
      collection1 = StimulusActionCollection.new(@action1)
      collection2 = StimulusActionCollection.new(@action2)
      collection3 = StimulusActionCollection.new(@action3)

      merged = collection1.merge(collection2, collection3)

      refute_same collection1, merged
      expected = {action: "foo--my-controller#myAction click->foo--my-controller#otherAction custom-controller#customAction"}
      assert_equal expected, merged.to_h
    end

    def test_merge_preserves_original_collections
      collection1 = StimulusActionCollection.new(@action1)
      collection2 = StimulusActionCollection.new(@action2)

      merged = collection1.merge(collection2)

      # Originals should be unchanged
      assert_equal({action: "foo--my-controller#myAction"}, collection1.to_h)
      assert_equal({action: "click->foo--my-controller#otherAction"}, collection2.to_h)
      # Merged should have both
      assert_equal({action: "foo--my-controller#myAction click->foo--my-controller#otherAction"}, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = StimulusActionCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = StimulusActionCollection.new(@action1)
      merged = StimulusActionCollection.merge(collection)

      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = StimulusActionCollection.new(@action1)
      collection2 = StimulusActionCollection.new(@action2)
      collection3 = StimulusActionCollection.new(@action3)

      merged = StimulusActionCollection.merge(collection1, collection2, collection3)

      refute_same collection1, merged
      expected = {action: "foo--my-controller#myAction click->foo--my-controller#otherAction custom-controller#customAction"}
      assert_equal expected, merged.to_h
    end

    def test_complex_real_world_scenario
      # Test with various action types and event handlers
      submit_action = StimulusAction.new(:submit, implied_controller: @implied_controller)
      click_action = StimulusAction.new(:click, :validate, implied_controller: @implied_controller)
      keydown_action = StimulusAction.new(:keydown, :handle_escape, implied_controller: @implied_controller)
      custom_event_action = StimulusAction.new(:custom_event, "modal_controller", :close, implied_controller: @implied_controller)

      collection = StimulusActionCollection.new([
        submit_action,
        click_action,
        keydown_action,
        custom_event_action
      ])

      expected = {
        action: "foo--my-controller#submit click->foo--my-controller#validate keydown->foo--my-controller#handleEscape custom_event->modal-controller#close"
      }
      assert_equal expected, collection.to_h
    end

    def test_merge_with_complex_actions
      # Create collections with different action patterns
      collection1 = StimulusActionCollection.new([
        StimulusAction.new(:submit, implied_controller: @implied_controller),
        StimulusAction.new(:click, "forms/validation_controller", :validate, implied_controller: @implied_controller)
      ])

      collection2 = StimulusActionCollection.new([
        StimulusAction.new(:focus, :clear_errors, implied_controller: @implied_controller),
        StimulusAction.new(:blur, "ui/feedback_controller", :show_hints, implied_controller: @implied_controller)
      ])

      merged = collection1.merge(collection2)

      expected = {
        action: "foo--my-controller#submit click->forms--validation-controller#validate focus->foo--my-controller#clearErrors blur->ui--feedback-controller#showHints"
      }
      assert_equal expected, merged.to_h
    end

    def test_inheritance_from_stimulus_collection_base
      collection = StimulusActionCollection.new
      assert_kind_of StimulusCollectionBase, collection
    end

    def test_duplicate_actions_are_preserved
      # Duplicate actions should be preserved (no deduplication)
      collection = StimulusActionCollection.new([@action1, @action1, @action2])
      expected = {action: "foo--my-controller#myAction foo--my-controller#myAction click->foo--my-controller#otherAction"}
      assert_equal expected, collection.to_h
    end

    def test_actions_with_different_event_patterns
      # Test various stimulus action patterns
      simple_action = StimulusAction.new(:simple_method, implied_controller: @implied_controller)
      event_action = StimulusAction.new(:click, :event_method, implied_controller: @implied_controller)
      controller_action = StimulusAction.new("other_controller", :controller_method, implied_controller: @implied_controller)
      full_action = StimulusAction.new(:keypress, "specific_controller", :full_method, implied_controller: @implied_controller)

      collection = StimulusActionCollection.new([
        simple_action,
        event_action,
        controller_action,
        full_action
      ])

      expected = {
        action: "foo--my-controller#simpleMethod click->foo--my-controller#eventMethod other-controller#controllerMethod keypress->specific-controller#fullMethod"
      }
      assert_equal expected, collection.to_h
    end

    def test_actions_with_special_characters_and_naming
      # Test snake_case to camelCase conversion
      snake_action = StimulusAction.new(:handle_form_submission, implied_controller: @implied_controller)
      nested_action = StimulusAction.new(:click, "admin/users_controller", :update_user_profile, implied_controller: @implied_controller)
      special_event = StimulusAction.new(:custom_event, :process_special_data, implied_controller: @implied_controller)

      collection = StimulusActionCollection.new([
        snake_action,
        nested_action,
        special_event
      ])

      expected = {
        action: "foo--my-controller#handleFormSubmission click->admin--users-controller#updateUserProfile custom_event->foo--my-controller#processSpecialData"
      }
      assert_equal expected, collection.to_h
    end

    def test_large_collection_performance
      # Test with a larger number of actions
      actions = 50.times.map do |i|
        StimulusAction.new(:"action_#{i}", implied_controller: @implied_controller)
      end

      collection = StimulusActionCollection.new(actions)

      result = collection.to_h
      assert result.key?(:action)

      action_strings = result[:action].split(" ")
      assert_equal 50, action_strings.length
      assert action_strings.all? { |action| action.match?(/^foo--my-controller#action\d+$/) }
    end

    def test_mixed_action_formats_in_single_collection
      # Test collection with all possible action formats
      format1 = StimulusAction.new("controller#action", implied_controller: @implied_controller)
      format2 = StimulusAction.new("click->controller#action", implied_controller: @implied_controller)
      format3 = StimulusAction.new(:method_name, implied_controller: @implied_controller)
      format4 = StimulusAction.new(:event, :method, implied_controller: @implied_controller)
      format5 = StimulusAction.new("controller", :method, implied_controller: @implied_controller)
      format6 = StimulusAction.new(:event, "controller", :method, implied_controller: @implied_controller)

      collection = StimulusActionCollection.new([
        format1, format2, format3, format4, format5, format6
      ])

      result = collection.to_h
      assert result.key?(:action)

      # Should contain multiple action strings separated by spaces
      actions = result[:action].split(" ")
      assert actions.length >= 6
    end
  end
end
