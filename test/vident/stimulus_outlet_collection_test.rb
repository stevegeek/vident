require "test_helper"

module Vident
  class StimulusOutletCollectionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
      @outlet1 = StimulusOutlet.new(:user_status, ".online-user", implied_controller: @implied_controller)
      @outlet2 = StimulusOutlet.new(:chat_status, ".chat-active", implied_controller: @implied_controller)
      @outlet3 = StimulusOutlet.new("custom_controller", :notification, "#notification-area", implied_controller: @implied_controller)
    end

    def test_initialization_with_no_arguments
      collection = StimulusOutletCollection.new
      assert collection.empty?
      assert_equal({}, collection.to_h)
    end

    def test_initialization_with_single_outlet
      collection = StimulusOutletCollection.new(@outlet1)
      refute collection.empty?
      assert_equal({"foo--my-controller-user-status-outlet" => ".online-user"}, collection.to_h)
    end

    def test_initialization_with_array_of_outlets
      collection = StimulusOutletCollection.new([@outlet1, @outlet2])
      refute collection.empty?
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_with_nested_arrays
      collection = StimulusOutletCollection.new([[@outlet1, @outlet2], @outlet3])
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active",
        "custom-controller-notification-outlet" => "#notification-area"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_filters_out_nils
      collection = StimulusOutletCollection.new([@outlet1, nil, @outlet2])
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active"
      }
      assert_equal expected, collection.to_h
    end

    def test_append_operator
      collection = StimulusOutletCollection.new
      collection << @outlet1
      collection << @outlet2

      refute collection.empty?
      assert collection.any?
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active"
      }
      assert_equal expected, collection.to_h
    end

    def test_append_operator_returns_self
      collection = StimulusOutletCollection.new
      result = collection << @outlet1
      assert_same collection, result
    end

    def test_to_h_with_empty_collection
      collection = StimulusOutletCollection.new
      assert_equal({}, collection.to_h)
    end

    def test_to_h_merges_outlet_hashes
      # Each outlet should contribute its own unique key-value pair
      outlet1 = StimulusOutlet.new(:sidebar, ".sidebar-component", implied_controller: @implied_controller)
      outlet2 = StimulusOutlet.new(:modal, "#modal-container", implied_controller: @implied_controller)
      outlet3 = StimulusOutlet.new("admin_controller", :dashboard, ".admin-dashboard", implied_controller: @implied_controller)

      collection = StimulusOutletCollection.new([outlet1, outlet2, outlet3])

      expected = {
        "foo--my-controller-sidebar-outlet" => ".sidebar-component",
        "foo--my-controller-modal-outlet" => "#modal-container",
        "admin-controller-dashboard-outlet" => ".admin-dashboard"
      }
      assert_equal expected, collection.to_h
    end

    def test_to_hash_alias
      collection = StimulusOutletCollection.new(@outlet1)
      assert_equal collection.to_h, collection.to_hash
    end

    def test_merge_with_empty_collection
      collection1 = StimulusOutletCollection.new(@outlet1)
      collection2 = StimulusOutletCollection.new

      merged = collection1.merge(collection2)

      refute_same collection1, merged
      assert_equal({"foo--my-controller-user-status-outlet" => ".online-user"}, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      collection1 = StimulusOutletCollection.new(@outlet1)
      collection2 = StimulusOutletCollection.new(@outlet2)

      merged = collection1.merge(collection2)

      refute_same collection1, merged
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_with_multiple_collections
      collection1 = StimulusOutletCollection.new(@outlet1)
      collection2 = StimulusOutletCollection.new(@outlet2)
      collection3 = StimulusOutletCollection.new(@outlet3)

      merged = collection1.merge(collection2, collection3)

      refute_same collection1, merged
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active",
        "custom-controller-notification-outlet" => "#notification-area"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_preserves_original_collections
      collection1 = StimulusOutletCollection.new(@outlet1)
      collection2 = StimulusOutletCollection.new(@outlet2)

      merged = collection1.merge(collection2)

      # Originals should be unchanged
      assert_equal({"foo--my-controller-user-status-outlet" => ".online-user"}, collection1.to_h)
      assert_equal({"foo--my-controller-chat-status-outlet" => ".chat-active"}, collection2.to_h)
      # Merged should have both
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_overwrites_duplicate_keys
      # If two outlets have the same key, the later one should overwrite
      outlet1 = StimulusOutlet.new(:status, ".status-v1", implied_controller: @implied_controller)
      outlet2 = StimulusOutlet.new(:status, ".status-v2", implied_controller: @implied_controller)

      collection1 = StimulusOutletCollection.new(outlet1)
      collection2 = StimulusOutletCollection.new(outlet2)

      merged = collection1.merge(collection2)

      # Second outlet should overwrite the first
      assert_equal({"foo--my-controller-status-outlet" => ".status-v2"}, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = StimulusOutletCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = StimulusOutletCollection.new(@outlet1)
      merged = StimulusOutletCollection.merge(collection)

      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = StimulusOutletCollection.new(@outlet1)
      collection2 = StimulusOutletCollection.new(@outlet2)
      collection3 = StimulusOutletCollection.new(@outlet3)

      merged = StimulusOutletCollection.merge(collection1, collection2, collection3)

      refute_same collection1, merged
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active",
        "custom-controller-notification-outlet" => "#notification-area"
      }
      assert_equal expected, merged.to_h
    end

    def test_complex_real_world_scenario
      # Test with various outlet types for different controllers and selectors
      sidebar_outlet = StimulusOutlet.new("layout/sidebar_controller", :navigation, ".main-nav", implied_controller: @implied_controller)
      modal_outlet = StimulusOutlet.new("ui/modal_controller", :dialog, "#modal-root", implied_controller: @implied_controller)
      toast_outlet = StimulusOutlet.new("notifications/toast_controller", :container, "[data-toast-container]", implied_controller: @implied_controller)
      dashboard_outlet = StimulusOutlet.new("admin/dashboard_controller", :widgets, ".widget-area", implied_controller: @implied_controller)

      collection = StimulusOutletCollection.new([
        sidebar_outlet,
        modal_outlet,
        toast_outlet,
        dashboard_outlet
      ])

      expected = {
        "layout--sidebar-controller-navigation-outlet" => ".main-nav",
        "ui--modal-controller-dialog-outlet" => "#modal-root",
        "notifications--toast-controller-container-outlet" => "[data-toast-container]",
        "admin--dashboard-controller-widgets-outlet" => ".widget-area"
      }
      assert_equal expected, collection.to_h
    end

    def test_merge_with_complex_outlets_from_different_controllers
      # Create collections with outlets from different controllers
      collection1 = StimulusOutletCollection.new([
        StimulusOutlet.new("forms/validation_controller", :error_display, ".error-container", implied_controller: @implied_controller),
        StimulusOutlet.new("forms/validation_controller", :success_display, ".success-container", implied_controller: @implied_controller)
      ])

      collection2 = StimulusOutletCollection.new([
        StimulusOutlet.new("ui/feedback_controller", :notification_area, "#notifications", implied_controller: @implied_controller),
        StimulusOutlet.new("forms/validation_controller", :warning_display, ".warning-container", implied_controller: @implied_controller)
      ])

      merged = collection1.merge(collection2)

      expected = {
        "forms--validation-controller-error-display-outlet" => ".error-container",
        "forms--validation-controller-success-display-outlet" => ".success-container",
        "ui--feedback-controller-notification-area-outlet" => "#notifications",
        "forms--validation-controller-warning-display-outlet" => ".warning-container"
      }
      assert_equal expected, merged.to_h
    end

    def test_inheritance_from_stimulus_collection_base
      collection = StimulusOutletCollection.new
      assert_kind_of StimulusCollectionBase, collection
    end

    def test_outlets_with_special_characters_and_naming
      # Test snake_case to kebab-case conversion and various selector types
      css_class_outlet = StimulusOutlet.new(:error_message_display, ".error-messages", implied_controller: @implied_controller)
      id_outlet = StimulusOutlet.new("admin/users_controller", :user_profile_modal, "#user-profile-modal", implied_controller: @implied_controller)
      attribute_outlet = StimulusOutlet.new(:data_table_container, "[data-table-container]", implied_controller: @implied_controller)
      complex_outlet = StimulusOutlet.new("analytics/reporting_controller", :chart_display_area, ".charts > .main-chart", implied_controller: @implied_controller)

      collection = StimulusOutletCollection.new([
        css_class_outlet,
        id_outlet,
        attribute_outlet,
        complex_outlet
      ])

      expected = {
        "foo--my-controller-error-message-display-outlet" => ".error-messages",
        "admin--users-controller-user-profile-modal-outlet" => "#user-profile-modal",
        "foo--my-controller-data-table-container-outlet" => "[data-table-container]",
        "analytics--reporting-controller-chart-display-area-outlet" => ".charts > .main-chart"
      }
      assert_equal expected, collection.to_h
    end

    def test_large_collection_performance
      # Test with a larger number of outlets
      outlets = 50.times.map do |i|
        StimulusOutlet.new(:"outlet_#{i}", ".selector-#{i}", implied_controller: @implied_controller)
      end

      collection = StimulusOutletCollection.new(outlets)

      result = collection.to_h
      assert_equal 50, result.size

      result.each do |key, value|
        assert key.match?(/^foo--my-controller-outlet-\d+-outlet$/)
        assert value.match?(/^\.selector-\d+$/)
      end
    end

    def test_duplicate_outlet_keys_overwrite_in_order
      # Test that when outlets have the same key, later ones overwrite earlier ones
      outlet1 = StimulusOutlet.new(:status, ".status-version-1", implied_controller: @implied_controller)
      outlet2 = StimulusOutlet.new(:status, ".status-version-2", implied_controller: @implied_controller)
      outlet3 = StimulusOutlet.new(:status, ".status-version-3", implied_controller: @implied_controller)

      collection = StimulusOutletCollection.new([outlet1, outlet2, outlet3])

      # Last outlet should win
      assert_equal({"foo--my-controller-status-outlet" => ".status-version-3"}, collection.to_h)
    end

    def test_merge_with_key_conflicts_across_collections
      # Test merging when different collections have outlets with same keys
      outlet1 = StimulusOutlet.new(:shared_outlet, ".collection1-selector", implied_controller: @implied_controller)
      outlet2 = StimulusOutlet.new(:shared_outlet, ".collection2-selector", implied_controller: @implied_controller)
      outlet3 = StimulusOutlet.new(:shared_outlet, ".collection3-selector", implied_controller: @implied_controller)

      collection1 = StimulusOutletCollection.new(outlet1)
      collection2 = StimulusOutletCollection.new(outlet2)
      collection3 = StimulusOutletCollection.new(outlet3)

      merged = StimulusOutletCollection.merge(collection1, collection2, collection3)

      # Last collection's outlet should win
      assert_equal({"foo--my-controller-shared-outlet-outlet" => ".collection3-selector"}, merged.to_h)
    end

    def test_outlets_with_various_selector_types
      # Test different CSS selector patterns
      id_outlet = StimulusOutlet.new(:by_id, "#unique-element", implied_controller: @implied_controller)
      class_outlet = StimulusOutlet.new(:by_class, ".multiple-elements", implied_controller: @implied_controller)
      attribute_outlet = StimulusOutlet.new(:by_attribute, "[data-role='modal']", implied_controller: @implied_controller)
      descendant_outlet = StimulusOutlet.new(:by_descendant, ".parent .child", implied_controller: @implied_controller)
      complex_outlet = StimulusOutlet.new(:complex_selector, "div.container > ul.list li:first-child", implied_controller: @implied_controller)

      collection = StimulusOutletCollection.new([
        id_outlet,
        class_outlet,
        attribute_outlet,
        descendant_outlet,
        complex_outlet
      ])

      expected = {
        "foo--my-controller-by-id-outlet" => "#unique-element",
        "foo--my-controller-by-class-outlet" => ".multiple-elements",
        "foo--my-controller-by-attribute-outlet" => "[data-role='modal']",
        "foo--my-controller-by-descendant-outlet" => ".parent .child",
        "foo--my-controller-complex-selector-outlet" => "div.container > ul.list li:first-child"
      }
      assert_equal expected, collection.to_h
    end
  end
end
