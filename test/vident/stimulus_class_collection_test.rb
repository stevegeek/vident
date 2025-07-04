require "test_helper"

module Vident
  class StimulusClassCollectionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
      @class1 = StimulusClass.new(:loading, "spinner active", implied_controller: @implied_controller)
      @class2 = StimulusClass.new(:error, "alert danger", implied_controller: @implied_controller)
      @class3 = StimulusClass.new("custom_controller", :success, "badge green", implied_controller: @implied_controller)
    end

    def test_initialization_with_no_arguments
      collection = StimulusClassCollection.new
      assert collection.empty?
      assert_equal({}, collection.to_h)
    end

    def test_initialization_with_single_class
      collection = StimulusClassCollection.new(@class1)
      refute collection.empty?
      assert_equal({ "foo--my-controller-loading-class" => "spinner active" }, collection.to_h)
    end

    def test_initialization_with_array_of_classes
      collection = StimulusClassCollection.new([@class1, @class2])
      refute collection.empty?
      expected = {
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_with_nested_arrays
      collection = StimulusClassCollection.new([[@class1, @class2], @class3])
      expected = { 
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger",
        "custom-controller-success-class" => "badge green"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_filters_out_nils
      collection = StimulusClassCollection.new([@class1, nil, @class2])
      expected = {
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger"
      }
      assert_equal expected, collection.to_h
    end

    def test_append_operator
      collection = StimulusClassCollection.new
      collection << @class1
      collection << @class2
      
      refute collection.empty?
      assert collection.any?
      expected = {
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger"
      }
      assert_equal expected, collection.to_h
    end

    def test_append_operator_returns_self
      collection = StimulusClassCollection.new
      result = collection << @class1
      assert_same collection, result
    end

    def test_to_h_with_empty_collection
      collection = StimulusClassCollection.new
      assert_equal({}, collection.to_h)
    end

    def test_to_h_merges_class_hashes
      # Each CSS class should contribute its own unique key-value pair
      button_class = StimulusClass.new(:button, "btn btn-primary", implied_controller: @implied_controller)
      input_class = StimulusClass.new(:input, "form-control", implied_controller: @implied_controller)
      modal_class = StimulusClass.new("modal_controller", :backdrop, "modal-backdrop fade", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([button_class, input_class, modal_class])
      
      expected = {
        "foo--my-controller-button-class" => "btn btn-primary",
        "foo--my-controller-input-class" => "form-control",
        "modal-controller-backdrop-class" => "modal-backdrop fade"
      }
      assert_equal expected, collection.to_h
    end

    def test_to_hash_alias
      collection = StimulusClassCollection.new(@class1)
      assert_equal collection.to_h, collection.to_hash
    end

    def test_merge_with_empty_collection
      collection1 = StimulusClassCollection.new(@class1)
      collection2 = StimulusClassCollection.new
      
      merged = collection1.merge(collection2)
      
      refute_same collection1, merged
      assert_equal({ "foo--my-controller-loading-class" => "spinner active" }, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      collection1 = StimulusClassCollection.new(@class1)
      collection2 = StimulusClassCollection.new(@class2)
      
      merged = collection1.merge(collection2)
      
      refute_same collection1, merged
      expected = {
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_with_multiple_collections
      collection1 = StimulusClassCollection.new(@class1)
      collection2 = StimulusClassCollection.new(@class2)
      collection3 = StimulusClassCollection.new(@class3)
      
      merged = collection1.merge(collection2, collection3)
      
      refute_same collection1, merged
      expected = { 
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger",
        "custom-controller-success-class" => "badge green"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_preserves_original_collections
      collection1 = StimulusClassCollection.new(@class1)
      collection2 = StimulusClassCollection.new(@class2)
      
      merged = collection1.merge(collection2)
      
      # Originals should be unchanged
      assert_equal({ "foo--my-controller-loading-class" => "spinner active" }, collection1.to_h)
      assert_equal({ "foo--my-controller-error-class" => "alert danger" }, collection2.to_h)
      # Merged should have both
      expected = {
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_overwrites_duplicate_keys
      # If two classes have the same key, the later one should overwrite
      class1 = StimulusClass.new(:state, "state-v1", implied_controller: @implied_controller)
      class2 = StimulusClass.new(:state, "state-v2", implied_controller: @implied_controller)
      
      collection1 = StimulusClassCollection.new(class1)
      collection2 = StimulusClassCollection.new(class2)
      
      merged = collection1.merge(collection2)
      
      # Second class should overwrite the first
      assert_equal({ "foo--my-controller-state-class" => "state-v2" }, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = StimulusClassCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = StimulusClassCollection.new(@class1)
      merged = StimulusClassCollection.merge(collection)
      
      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = StimulusClassCollection.new(@class1)
      collection2 = StimulusClassCollection.new(@class2)
      collection3 = StimulusClassCollection.new(@class3)
      
      merged = StimulusClassCollection.merge(collection1, collection2, collection3)
      
      refute_same collection1, merged
      expected = { 
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger",
        "custom-controller-success-class" => "badge green"
      }
      assert_equal expected, merged.to_h
    end

    def test_complex_real_world_scenario
      # Test with various CSS class types for different controllers and states
      form_loading = StimulusClass.new("forms/signup_controller", :loading, "opacity-50 pointer-events-none", implied_controller: @implied_controller)
      form_error = StimulusClass.new("forms/signup_controller", :error, "border-red-500 bg-red-50", implied_controller: @implied_controller)
      modal_open = StimulusClass.new("ui/modal_controller", :open, "opacity-100 scale-100 z-50", implied_controller: @implied_controller)
      button_primary = StimulusClass.new("ui/button_controller", :primary, "bg-blue-600 hover:bg-blue-700 text-white", implied_controller: @implied_controller)
      notification_show = StimulusClass.new("notifications/toast_controller", :show, "transform translate-y-0 opacity-100", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([
        form_loading,
        form_error,
        modal_open,
        button_primary,
        notification_show
      ])
      
      expected = { 
        "forms--signup-controller-loading-class" => "opacity-50 pointer-events-none",
        "forms--signup-controller-error-class" => "border-red-500 bg-red-50",
        "ui--modal-controller-open-class" => "opacity-100 scale-100 z-50",
        "ui--button-controller-primary-class" => "bg-blue-600 hover:bg-blue-700 text-white",
        "notifications--toast-controller-show-class" => "transform translate-y-0 opacity-100"
      }
      assert_equal expected, collection.to_h
    end

    def test_merge_with_complex_classes_from_different_controllers
      # Create collections with classes from different controllers
      collection1 = StimulusClassCollection.new([
        StimulusClass.new("admin/dashboard_controller", :sidebar_open, "w-64 translate-x-0", implied_controller: @implied_controller),
        StimulusClass.new("admin/dashboard_controller", :sidebar_closed, "w-0 -translate-x-full", implied_controller: @implied_controller)
      ])
      
      collection2 = StimulusClassCollection.new([
        StimulusClass.new("ui/dropdown_controller", :menu_open, "opacity-100 scale-100", implied_controller: @implied_controller),
        StimulusClass.new("admin/dashboard_controller", :content_shifted, "ml-64", implied_controller: @implied_controller)
      ])
      
      merged = collection1.merge(collection2)
      
      expected = {
        "admin--dashboard-controller-sidebar-open-class" => "w-64 translate-x-0",
        "admin--dashboard-controller-sidebar-closed-class" => "w-0 -translate-x-full",
        "ui--dropdown-controller-menu-open-class" => "opacity-100 scale-100",
        "admin--dashboard-controller-content-shifted-class" => "ml-64"
      }
      assert_equal expected, merged.to_h
    end

    def test_inheritance_from_stimulus_collection_base
      collection = StimulusClassCollection.new
      assert_kind_of StimulusCollectionBase, collection
    end

    def test_classes_with_special_characters_and_naming
      # Test snake_case to kebab-case conversion and various CSS class patterns
      utility_class = StimulusClass.new(:button_hover_state, "bg-blue-500 hover:bg-blue-600", implied_controller: @implied_controller)
      nested_class = StimulusClass.new("admin/users_controller", :table_row_selected, "bg-gray-100 border-blue-500", implied_controller: @implied_controller)
      responsive_class = StimulusClass.new(:mobile_navigation, "block md:hidden lg:flex", implied_controller: @implied_controller)
      animation_class = StimulusClass.new("animations/fade_controller", :transition_in, "transition-all duration-300 ease-in-out", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([
        utility_class,
        nested_class,
        responsive_class,
        animation_class
      ])
      
      expected = {
        "foo--my-controller-button-hover-state-class" => "bg-blue-500 hover:bg-blue-600",
        "admin--users-controller-table-row-selected-class" => "bg-gray-100 border-blue-500",
        "foo--my-controller-mobile-navigation-class" => "block md:hidden lg:flex",
        "animations--fade-controller-transition-in-class" => "transition-all duration-300 ease-in-out"
      }
      assert_equal expected, collection.to_h
    end

    def test_large_collection_performance
      # Test with a larger number of CSS classes
      classes = 50.times.map do |i|
        StimulusClass.new("class_#{i}".to_sym, "style-#{i} color-#{i}", implied_controller: @implied_controller)
      end
      
      collection = StimulusClassCollection.new(classes)
      
      result = collection.to_h
      assert_equal 50, result.size
      
      result.each do |key, value|
        assert key.match?(/^foo--my-controller-class-\d+-class$/)
        assert value.match?(/^style-\d+ color-\d+$/)
      end
    end

    def test_duplicate_class_keys_overwrite_in_order
      # Test that when classes have the same key, later ones overwrite earlier ones
      class1 = StimulusClass.new(:theme, "theme-light", implied_controller: @implied_controller)
      class2 = StimulusClass.new(:theme, "theme-dark", implied_controller: @implied_controller)
      class3 = StimulusClass.new(:theme, "theme-auto", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([class1, class2, class3])
      
      # Last class should win
      assert_equal({ "foo--my-controller-theme-class" => "theme-auto" }, collection.to_h)
    end

    def test_merge_with_key_conflicts_across_collections
      # Test merging when different collections have classes with same keys
      class1 = StimulusClass.new(:shared_state, "collection1-style", implied_controller: @implied_controller)
      class2 = StimulusClass.new(:shared_state, "collection2-style", implied_controller: @implied_controller)
      class3 = StimulusClass.new(:shared_state, "collection3-style", implied_controller: @implied_controller)
      
      collection1 = StimulusClassCollection.new(class1)
      collection2 = StimulusClassCollection.new(class2)
      collection3 = StimulusClassCollection.new(class3)
      
      merged = StimulusClassCollection.merge(collection1, collection2, collection3)
      
      # Last collection's class should win
      assert_equal({ "foo--my-controller-shared-state-class" => "collection3-style" }, merged.to_h)
    end

    def test_classes_with_various_css_patterns
      # Test different CSS class patterns and frameworks
      tailwind_class = StimulusClass.new(:tailwind_button, "px-4 py-2 bg-blue-500 text-white rounded-lg shadow-md hover:bg-blue-600", implied_controller: @implied_controller)
      bootstrap_class = StimulusClass.new(:bootstrap_alert, "alert alert-warning alert-dismissible fade show", implied_controller: @implied_controller)
      custom_class = StimulusClass.new(:custom_component, "my-custom-component--active my-custom-component--highlighted", implied_controller: @implied_controller)
      utility_class = StimulusClass.new(:utility_mix, "d-flex justify-content-center align-items-center", implied_controller: @implied_controller)
      responsive_class = StimulusClass.new(:responsive_grid, "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([
        tailwind_class,
        bootstrap_class,
        custom_class,
        utility_class,
        responsive_class
      ])
      
      expected = {
        "foo--my-controller-tailwind-button-class" => "px-4 py-2 bg-blue-500 text-white rounded-lg shadow-md hover:bg-blue-600",
        "foo--my-controller-bootstrap-alert-class" => "alert alert-warning alert-dismissible fade show",
        "foo--my-controller-custom-component-class" => "my-custom-component--active my-custom-component--highlighted",
        "foo--my-controller-utility-mix-class" => "d-flex justify-content-center align-items-center",
        "foo--my-controller-responsive-grid-class" => "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4"
      }
      assert_equal expected, collection.to_h
    end

    def test_classes_with_array_input
      # Test StimulusClass that accepts array of class names
      array_class = StimulusClass.new(:multi_classes, ["btn", "btn-primary", "btn-lg"], implied_controller: @implied_controller)
      string_class = StimulusClass.new(:single_class, "simple-class", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([array_class, string_class])
      
      expected = {
        "foo--my-controller-multi-classes-class" => "btn btn-primary btn-lg",
        "foo--my-controller-single-class-class" => "simple-class"
      }
      assert_equal expected, collection.to_h
    end

    def test_empty_and_whitespace_class_handling
      # Test how collection handles empty strings and whitespace
      empty_class = StimulusClass.new(:empty_state, "", implied_controller: @implied_controller)
      whitespace_class = StimulusClass.new(:whitespace_state, "   ", implied_controller: @implied_controller)
      normal_class = StimulusClass.new(:normal_state, "normal-class", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([empty_class, whitespace_class, normal_class])
      
      result = collection.to_h
      
      # All classes should be preserved as-is (StimulusClass handles normalization)
      assert result.key?("foo--my-controller-empty-state-class")
      assert result.key?("foo--my-controller-whitespace-state-class")
      assert_equal "normal-class", result["foo--my-controller-normal-state-class"]
    end

    def test_unicode_and_special_characters_in_class_names
      # Test class names with unicode and special characters
      unicode_class = StimulusClass.new(:unicode_state, "class-with-🎨-emoji", implied_controller: @implied_controller)
      special_chars = StimulusClass.new(:special_state, "class_with-special.chars:hover", implied_controller: @implied_controller)
      
      collection = StimulusClassCollection.new([unicode_class, special_chars])
      
      result = collection.to_h
      
      assert_equal "class-with-🎨-emoji", result["foo--my-controller-unicode-state-class"]
      assert_equal "class_with-special.chars:hover", result["foo--my-controller-special-state-class"]
    end
  end
end