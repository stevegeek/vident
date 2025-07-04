require "test_helper"

module Vident
  class StimulusControllerCollectionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @controller1 = StimulusController.new("my_controller", implied_controller: @implied_controller_path)
      @controller2 = StimulusController.new("other_controller", implied_controller: @implied_controller_path)
      @controller3 = StimulusController.new("path/to/nested_controller", implied_controller: @implied_controller_path)
    end

    def test_initialization_with_no_arguments
      collection = StimulusControllerCollection.new
      assert collection.empty?
      assert_equal({}, collection.to_h)
    end

    def test_initialization_with_single_controller
      collection = StimulusControllerCollection.new(@controller1)
      refute collection.empty?
      assert_equal({ controller: "my-controller" }, collection.to_h)
    end

    def test_initialization_with_array_of_controllers
      collection = StimulusControllerCollection.new([@controller1, @controller2])
      refute collection.empty?
      assert_equal({ controller: "my-controller other-controller" }, collection.to_h)
    end

    def test_initialization_with_nested_arrays
      collection = StimulusControllerCollection.new([[@controller1, @controller2], @controller3])
      assert_equal({ controller: "my-controller other-controller path--to--nested-controller" }, collection.to_h)
    end

    def test_initialization_filters_out_nils
      collection = StimulusControllerCollection.new([@controller1, nil, @controller2])
      assert_equal({ controller: "my-controller other-controller" }, collection.to_h)
    end

    def test_append_operator
      collection = StimulusControllerCollection.new
      collection << @controller1
      collection << @controller2
      
      refute collection.empty?
      assert collection.any?
      assert_equal({ controller: "my-controller other-controller" }, collection.to_h)
    end

    def test_append_operator_returns_self
      collection = StimulusControllerCollection.new
      result = collection << @controller1
      assert_same collection, result
    end

    def test_to_h_with_empty_collection
      collection = StimulusControllerCollection.new
      assert_equal({}, collection.to_h)
    end

    def test_to_h_filters_empty_controller_strings
      # Create a mock controller that returns empty string
      empty_controller = Object.new
      def empty_controller.to_s
        ""
      end
      
      collection = StimulusControllerCollection.new([@controller1, empty_controller, @controller2])
      assert_equal({ controller: "my-controller other-controller" }, collection.to_h)
    end

    def test_to_h_handles_all_empty_controllers
      empty_controller1 = Object.new
      def empty_controller1.to_s
        ""
      end
      
      empty_controller2 = Object.new  
      def empty_controller2.to_s
        ""
      end
      
      collection = StimulusControllerCollection.new([empty_controller1, empty_controller2])
      assert_equal({}, collection.to_h)
    end

    def test_to_hash_alias
      collection = StimulusControllerCollection.new(@controller1)
      assert_equal collection.to_h, collection.to_hash
    end

    def test_merge_with_empty_collection
      collection1 = StimulusControllerCollection.new(@controller1)
      collection2 = StimulusControllerCollection.new
      
      merged = collection1.merge(collection2)
      
      refute_same collection1, merged
      assert_equal({ controller: "my-controller" }, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      collection1 = StimulusControllerCollection.new(@controller1)
      collection2 = StimulusControllerCollection.new(@controller2)
      
      merged = collection1.merge(collection2)
      
      refute_same collection1, merged
      assert_equal({ controller: "my-controller other-controller" }, merged.to_h)
    end

    def test_merge_with_multiple_collections
      collection1 = StimulusControllerCollection.new(@controller1)
      collection2 = StimulusControllerCollection.new(@controller2)
      collection3 = StimulusControllerCollection.new(@controller3)
      
      merged = collection1.merge(collection2, collection3)
      
      refute_same collection1, merged
      assert_equal({ controller: "my-controller other-controller path--to--nested-controller" }, merged.to_h)
    end

    def test_merge_preserves_original_collections
      collection1 = StimulusControllerCollection.new(@controller1)
      collection2 = StimulusControllerCollection.new(@controller2)
      
      merged = collection1.merge(collection2)
      
      # Originals should be unchanged
      assert_equal({ controller: "my-controller" }, collection1.to_h)
      assert_equal({ controller: "other-controller" }, collection2.to_h)
      # Merged should have both
      assert_equal({ controller: "my-controller other-controller" }, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = StimulusControllerCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = StimulusControllerCollection.new(@controller1)
      merged = StimulusControllerCollection.merge(collection)
      
      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = StimulusControllerCollection.new(@controller1)
      collection2 = StimulusControllerCollection.new(@controller2)
      collection3 = StimulusControllerCollection.new(@controller3)
      
      merged = StimulusControllerCollection.merge(collection1, collection2, collection3)
      
      refute_same collection1, merged
      assert_equal({ controller: "my-controller other-controller path--to--nested-controller" }, merged.to_h)
    end

    def test_complex_real_world_scenario
      # Test with various controller types and naming patterns
      main_controller = StimulusController.new("form_controller", implied_controller: @implied_controller_path)
      modal_controller = StimulusController.new("modals/popup_controller", implied_controller: @implied_controller_path)
      validation_controller = StimulusController.new("validation/field_validator_controller", implied_controller: @implied_controller_path)
      ui_controller = StimulusController.new("ui/dropdown_controller", implied_controller: @implied_controller_path)
      
      collection = StimulusControllerCollection.new([
        main_controller,
        modal_controller,
        validation_controller,
        ui_controller
      ])
      
      expected = { 
        controller: "form-controller modals--popup-controller validation--field-validator-controller ui--dropdown-controller"
      }
      assert_equal expected, collection.to_h
    end

    def test_merge_with_complex_controllers
      # Create collections with different controller naming patterns
      collection1 = StimulusControllerCollection.new([
        StimulusController.new("simple_controller", implied_controller: @implied_controller_path),
        StimulusController.new("admin/users_controller", implied_controller: @implied_controller_path)
      ])
      
      collection2 = StimulusControllerCollection.new([
        StimulusController.new("ui/components/modal_controller", implied_controller: @implied_controller_path),
        StimulusController.new("api/v1/data_controller", implied_controller: @implied_controller_path)
      ])
      
      merged = collection1.merge(collection2)
      
      expected = {
        controller: "simple-controller admin--users-controller ui--components--modal-controller api--v1--data-controller"
      }
      assert_equal expected, merged.to_h
    end

    def test_inheritance_from_stimulus_collection_base
      collection = StimulusControllerCollection.new
      assert_kind_of StimulusCollectionBase, collection
    end

    def test_duplicate_controllers_are_preserved
      # Duplicate controllers should be preserved (no deduplication)
      collection = StimulusControllerCollection.new([@controller1, @controller1, @controller2])
      assert_equal({ controller: "my-controller my-controller other-controller" }, collection.to_h)
    end

    def test_mixed_controller_types_and_empty_strings
      regular_controller = StimulusController.new("regular", implied_controller: @implied_controller_path)
      
      empty_controller = Object.new
      def empty_controller.to_s
        ""
      end
      
      nested_controller = StimulusController.new("deep/nested/controller", implied_controller: @implied_controller_path)
      
      collection = StimulusControllerCollection.new([
        regular_controller,
        empty_controller,
        nested_controller,
        empty_controller
      ])
      
      # Empty controllers should be filtered out
      assert_equal({ controller: "regular deep--nested--controller" }, collection.to_h)
    end

    def test_large_collection_performance
      # Test with a larger number of controllers
      controllers = 50.times.map do |i|
        StimulusController.new("controller_#{i}", implied_controller: @implied_controller_path)
      end
      
      collection = StimulusControllerCollection.new(controllers)
      
      result = collection.to_h
      assert result.key?(:controller)
      
      controller_names = result[:controller].split(" ")
      assert_equal 50, controller_names.length
      assert controller_names.all? { |name| name.match?(/^controller-\d+$/) }
    end
  end
end