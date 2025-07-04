require "test_helper"

module Vident
  class StimulusCollectionBaseTest < Minitest::Test
    # Test concrete implementation of abstract base class
    class TestCollection < StimulusCollectionBase
      def to_h
        return {} if items.empty?
        { test: items.map(&:to_s).join(" ") }
      end
    end

    def setup
      @collection = TestCollection.new
    end

    def test_initialization_with_no_arguments
      collection = TestCollection.new
      assert collection.empty?
      refute collection.any?
    end

    def test_initialization_with_single_item
      collection = TestCollection.new("item1")
      refute collection.empty?
      assert collection.any?
    end

    def test_initialization_with_array_of_items
      collection = TestCollection.new(["item1", "item2", "item3"])
      refute collection.empty?
      assert collection.any?
    end

    def test_initialization_with_nested_arrays
      collection = TestCollection.new([["item1", "item2"], "item3"])
      refute collection.empty?
      assert collection.any?
      assert_equal({ test: "item1 item2 item3" }, collection.to_h)
    end

    def test_initialization_filters_out_nils
      collection = TestCollection.new(["item1", nil, "item2", nil])
      assert_equal({ test: "item1 item2" }, collection.to_h)
    end

    def test_append_operator
      @collection << "item1"
      @collection << "item2"
      
      refute @collection.empty?
      assert @collection.any?
      assert_equal({ test: "item1 item2" }, @collection.to_h)
    end

    def test_append_operator_returns_self
      result = @collection << "item1"
      assert_same @collection, result
    end

    def test_to_hash_alias
      @collection << "item1"
      assert_equal @collection.to_h, @collection.to_hash
    end

    def test_empty_and_any_predicates
      assert @collection.empty?
      refute @collection.any?
      
      @collection << "item1"
      
      refute @collection.empty?
      assert @collection.any?
    end

    def test_merge_with_empty_collection
      @collection << "item1"
      other_collection = TestCollection.new
      
      merged = @collection.merge(other_collection)
      
      refute_same @collection, merged
      assert_equal({ test: "item1" }, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      @collection << "item1"
      other_collection = TestCollection.new(["item2", "item3"])
      
      merged = @collection.merge(other_collection)
      
      refute_same @collection, merged
      assert_equal({ test: "item1 item2 item3" }, merged.to_h)
    end

    def test_merge_with_multiple_collections
      @collection << "item1"
      collection2 = TestCollection.new("item2")
      collection3 = TestCollection.new(["item3", "item4"])
      
      merged = @collection.merge(collection2, collection3)
      
      refute_same @collection, merged
      assert_equal({ test: "item1 item2 item3 item4" }, merged.to_h)
    end

    def test_merge_ignores_non_matching_collection_types
      @collection << "item1"
      
      # Different collection type should be ignored
      other_type_collection = Class.new(StimulusCollectionBase) do
        def to_h
          { other: "value" }
        end
      end.new("item2")
      
      merged = @collection.merge(other_type_collection)
      
      assert_equal({ test: "item1" }, merged.to_h)
    end

    def test_merge_preserves_original_collection
      @collection << "item1"
      other_collection = TestCollection.new("item2")
      
      merged = @collection.merge(other_collection)
      
      # Original should be unchanged
      assert_equal({ test: "item1" }, @collection.to_h)
      # Other should be unchanged
      assert_equal({ test: "item2" }, other_collection.to_h)
      # Merged should have both
      assert_equal({ test: "item1 item2" }, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = TestCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = TestCollection.new("item1")
      merged = TestCollection.merge(collection)
      
      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = TestCollection.new("item1")
      collection2 = TestCollection.new("item2")
      collection3 = TestCollection.new(["item3", "item4"])
      
      merged = TestCollection.merge(collection1, collection2, collection3)
      
      refute_same collection1, merged
      assert_equal({ test: "item1 item2 item3 item4" }, merged.to_h)
    end

    def test_to_h_must_be_implemented_by_subclasses
      base_collection = StimulusCollectionBase.new("item1")
      
      assert_raises(NoMethodError) do
        base_collection.to_h
      end
    end

    def test_items_accessor_is_protected
      @collection << "item1"
      
      # Should not be able to access items directly from outside
      assert_raises(NoMethodError) do
        @collection.items
      end
      
      # But subclasses should be able to access it (tested implicitly in to_h implementation)
    end

    def test_complex_merge_scenario
      # Create multiple collections with different items
      collection1 = TestCollection.new(["base1", "base2"])
      collection2 = TestCollection.new("middle")
      collection3 = TestCollection.new(["end1", "end2", "end3"])
      
      # Test chained merges
      step1 = collection1.merge(collection2)
      final = step1.merge(collection3)
      
      assert_equal({ test: "base1 base2 middle end1 end2 end3" }, final.to_h)
      
      # Test direct merge with multiple arguments
      direct_merge = collection1.merge(collection2, collection3)
      
      assert_equal final.to_h, direct_merge.to_h
    end

    def test_merge_with_empty_collections_in_chain
      collection1 = TestCollection.new("item1")
      empty_collection = TestCollection.new
      collection2 = TestCollection.new("item2")
      
      merged = collection1.merge(empty_collection, collection2)
      
      assert_equal({ test: "item1 item2" }, merged.to_h)
    end
  end
end