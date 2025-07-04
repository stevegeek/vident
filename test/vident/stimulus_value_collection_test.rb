require "test_helper"

module Vident
  class StimulusValueCollectionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
      @value1 = StimulusValue.new(:url, "https://example.com", implied_controller: @implied_controller)
      @value2 = StimulusValue.new(:timeout, 5000, implied_controller: @implied_controller)
      @value3 = StimulusValue.new("custom_controller", :api_key, "secret123", implied_controller: @implied_controller)
    end

    def test_initialization_with_no_arguments
      collection = StimulusValueCollection.new
      assert collection.empty?
      assert_equal({}, collection.to_h)
    end

    def test_initialization_with_single_value
      collection = StimulusValueCollection.new(@value1)
      refute collection.empty?
      assert_equal({"foo--my-controller-url-value" => "https://example.com"}, collection.to_h)
    end

    def test_initialization_with_array_of_values
      collection = StimulusValueCollection.new([@value1, @value2])
      refute collection.empty?
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_with_nested_arrays
      collection = StimulusValueCollection.new([[@value1, @value2], @value3])
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000",
        "custom-controller-api-key-value" => "secret123"
      }
      assert_equal expected, collection.to_h
    end

    def test_initialization_filters_out_nils
      collection = StimulusValueCollection.new([@value1, nil, @value2])
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000"
      }
      assert_equal expected, collection.to_h
    end

    def test_append_operator
      collection = StimulusValueCollection.new
      collection << @value1
      collection << @value2

      refute collection.empty?
      assert collection.any?
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000"
      }
      assert_equal expected, collection.to_h
    end

    def test_append_operator_returns_self
      collection = StimulusValueCollection.new
      result = collection << @value1
      assert_same collection, result
    end

    def test_to_h_with_empty_collection
      collection = StimulusValueCollection.new
      assert_equal({}, collection.to_h)
    end

    def test_to_h_merges_value_hashes
      # Each value should contribute its own unique key-value pair
      string_value = StimulusValue.new(:endpoint, "/api/users", implied_controller: @implied_controller)
      number_value = StimulusValue.new(:retry_count, 3, implied_controller: @implied_controller)
      boolean_value = StimulusValue.new(:enabled, true, implied_controller: @implied_controller)
      array_value = StimulusValue.new(:tags, ["red", "blue", "green"], implied_controller: @implied_controller)
      hash_value = StimulusValue.new(:config, {theme: "dark", lang: "en"}, implied_controller: @implied_controller)

      collection = StimulusValueCollection.new([
        string_value, number_value, boolean_value, array_value, hash_value
      ])

      expected = {
        "foo--my-controller-endpoint-value" => "/api/users",
        "foo--my-controller-retry-count-value" => "3",
        "foo--my-controller-enabled-value" => "true",
        "foo--my-controller-tags-value" => '["red","blue","green"]',
        "foo--my-controller-config-value" => '{"theme":"dark","lang":"en"}'
      }
      assert_equal expected, collection.to_h
    end

    def test_to_hash_alias
      collection = StimulusValueCollection.new(@value1)
      assert_equal collection.to_h, collection.to_hash
    end

    def test_merge_with_empty_collection
      collection1 = StimulusValueCollection.new(@value1)
      collection2 = StimulusValueCollection.new

      merged = collection1.merge(collection2)

      refute_same collection1, merged
      assert_equal({"foo--my-controller-url-value" => "https://example.com"}, merged.to_h)
    end

    def test_merge_with_non_empty_collection
      collection1 = StimulusValueCollection.new(@value1)
      collection2 = StimulusValueCollection.new(@value2)

      merged = collection1.merge(collection2)

      refute_same collection1, merged
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_with_multiple_collections
      collection1 = StimulusValueCollection.new(@value1)
      collection2 = StimulusValueCollection.new(@value2)
      collection3 = StimulusValueCollection.new(@value3)

      merged = collection1.merge(collection2, collection3)

      refute_same collection1, merged
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000",
        "custom-controller-api-key-value" => "secret123"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_preserves_original_collections
      collection1 = StimulusValueCollection.new(@value1)
      collection2 = StimulusValueCollection.new(@value2)

      merged = collection1.merge(collection2)

      # Originals should be unchanged
      assert_equal({"foo--my-controller-url-value" => "https://example.com"}, collection1.to_h)
      assert_equal({"foo--my-controller-timeout-value" => "5000"}, collection2.to_h)
      # Merged should have both
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000"
      }
      assert_equal expected, merged.to_h
    end

    def test_merge_overwrites_duplicate_keys
      # If two values have the same key, the later one should overwrite
      value1 = StimulusValue.new(:config, "config-v1", implied_controller: @implied_controller)
      value2 = StimulusValue.new(:config, "config-v2", implied_controller: @implied_controller)

      collection1 = StimulusValueCollection.new(value1)
      collection2 = StimulusValueCollection.new(value2)

      merged = collection1.merge(collection2)

      # Second value should overwrite the first
      assert_equal({"foo--my-controller-config-value" => "config-v2"}, merged.to_h)
    end

    def test_class_merge_with_no_collections
      merged = StimulusValueCollection.merge
      assert merged.empty?
      assert_equal({}, merged.to_h)
    end

    def test_class_merge_with_single_collection
      collection = StimulusValueCollection.new(@value1)
      merged = StimulusValueCollection.merge(collection)

      assert_same collection, merged
    end

    def test_class_merge_with_multiple_collections
      collection1 = StimulusValueCollection.new(@value1)
      collection2 = StimulusValueCollection.new(@value2)
      collection3 = StimulusValueCollection.new(@value3)

      merged = StimulusValueCollection.merge(collection1, collection2, collection3)

      refute_same collection1, merged
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000",
        "custom-controller-api-key-value" => "secret123"
      }
      assert_equal expected, merged.to_h
    end

    def test_complex_real_world_scenario
      # Test with various value types for different controllers
      api_config = StimulusValue.new("api/client_controller", :base_url, "https://api.example.com/v1", implied_controller: @implied_controller)
      ui_settings = StimulusValue.new("ui/theme_controller", :dark_mode, true, implied_controller: @implied_controller)
      form_config = StimulusValue.new("forms/validation_controller", :required_fields, ["email", "name"], implied_controller: @implied_controller)
      timing_config = StimulusValue.new("animations/fade_controller", :duration, 300, implied_controller: @implied_controller)
      user_prefs = StimulusValue.new("user/preferences_controller", :settings, {notifications: true, theme: "auto"}, implied_controller: @implied_controller)

      collection = StimulusValueCollection.new([
        api_config,
        ui_settings,
        form_config,
        timing_config,
        user_prefs
      ])

      expected = {
        "api--client-controller-base-url-value" => "https://api.example.com/v1",
        "ui--theme-controller-dark-mode-value" => "true",
        "forms--validation-controller-required-fields-value" => '["email","name"]',
        "animations--fade-controller-duration-value" => "300",
        "user--preferences-controller-settings-value" => '{"notifications":true,"theme":"auto"}'
      }
      assert_equal expected, collection.to_h
    end

    def test_merge_with_complex_values_from_different_controllers
      # Create collections with values from different controllers
      collection1 = StimulusValueCollection.new([
        StimulusValue.new("forms/signup_controller", :endpoint, "/api/signup", implied_controller: @implied_controller),
        StimulusValue.new("forms/signup_controller", :method, "POST", implied_controller: @implied_controller)
      ])

      collection2 = StimulusValueCollection.new([
        StimulusValue.new("validation/email_controller", :pattern, "^[^@]+@[^@]+.[^@]+$", implied_controller: @implied_controller),
        StimulusValue.new("forms/signup_controller", :timeout, 5000, implied_controller: @implied_controller)
      ])

      merged = collection1.merge(collection2)

      expected = {
        "forms--signup-controller-endpoint-value" => "/api/signup",
        "forms--signup-controller-method-value" => "POST",
        "validation--email-controller-pattern-value" => "^[^@]+@[^@]+.[^@]+$",
        "forms--signup-controller-timeout-value" => "5000"
      }
      assert_equal expected, merged.to_h
    end

    def test_inheritance_from_stimulus_collection_base
      collection = StimulusValueCollection.new
      assert_kind_of StimulusCollectionBase, collection
    end

    def test_values_with_special_characters_and_naming
      # Test snake_case to kebab-case conversion and JSON serialization
      string_value = StimulusValue.new(:api_endpoint_url, "https://api.example.com/users", implied_controller: @implied_controller)
      nested_value = StimulusValue.new("admin/users_controller", :max_retry_attempts, 3, implied_controller: @implied_controller)
      complex_value = StimulusValue.new(:user_preferences, {
        theme: "dark",
        language: "en-US",
        notifications: {
          email: true,
          push: false
        }
      }, implied_controller: @implied_controller)

      collection = StimulusValueCollection.new([
        string_value,
        nested_value,
        complex_value
      ])

      expected = {
        "foo--my-controller-api-endpoint-url-value" => "https://api.example.com/users",
        "admin--users-controller-max-retry-attempts-value" => "3",
        "foo--my-controller-user-preferences-value" => '{"theme":"dark","language":"en-US","notifications":{"email":true,"push":false}}'
      }
      assert_equal expected, collection.to_h
    end

    def test_large_collection_performance
      # Test with a larger number of values
      values = 50.times.map do |i|
        StimulusValue.new(:"value_#{i}", "data-#{i}", implied_controller: @implied_controller)
      end

      collection = StimulusValueCollection.new(values)

      result = collection.to_h
      assert_equal 50, result.size

      result.each do |key, value|
        assert key.match?(/^foo--my-controller-value-\d+-value$/)
        assert value.match?(/^data-\d+$/)
      end
    end

    def test_duplicate_value_keys_overwrite_in_order
      # Test that when values have the same key, later ones overwrite earlier ones
      value1 = StimulusValue.new(:config, "config-v1", implied_controller: @implied_controller)
      value2 = StimulusValue.new(:config, "config-v2", implied_controller: @implied_controller)
      value3 = StimulusValue.new(:config, "config-v3", implied_controller: @implied_controller)

      collection = StimulusValueCollection.new([value1, value2, value3])

      # Last value should win
      assert_equal({"foo--my-controller-config-value" => "config-v3"}, collection.to_h)
    end

    def test_merge_with_key_conflicts_across_collections
      # Test merging when different collections have values with same keys
      value1 = StimulusValue.new(:shared_config, "collection1-value", implied_controller: @implied_controller)
      value2 = StimulusValue.new(:shared_config, "collection2-value", implied_controller: @implied_controller)
      value3 = StimulusValue.new(:shared_config, "collection3-value", implied_controller: @implied_controller)

      collection1 = StimulusValueCollection.new(value1)
      collection2 = StimulusValueCollection.new(value2)
      collection3 = StimulusValueCollection.new(value3)

      merged = StimulusValueCollection.merge(collection1, collection2, collection3)

      # Last collection's value should win
      assert_equal({"foo--my-controller-shared-config-value" => "collection3-value"}, merged.to_h)
    end

    def test_values_with_various_data_types
      # Test different data types and their JSON serialization
      string_value = StimulusValue.new(:string_val, "hello world", implied_controller: @implied_controller)
      integer_value = StimulusValue.new(:integer_val, 42, implied_controller: @implied_controller)
      float_value = StimulusValue.new(:float_val, 3.14159, implied_controller: @implied_controller)
      boolean_true = StimulusValue.new(:bool_true, true, implied_controller: @implied_controller)
      boolean_false = StimulusValue.new(:bool_false, false, implied_controller: @implied_controller)
      null_value = StimulusValue.new(:null_val, nil, implied_controller: @implied_controller)
      array_value = StimulusValue.new(:array_val, [1, "two", true, nil], implied_controller: @implied_controller)
      hash_value = StimulusValue.new(:hash_val, {key1: "value1", key2: 2, key3: false}, implied_controller: @implied_controller)

      collection = StimulusValueCollection.new([
        string_value,
        integer_value,
        float_value,
        boolean_true,
        boolean_false,
        null_value,
        array_value,
        hash_value
      ])

      expected = {
        "foo--my-controller-string-val-value" => "hello world",
        "foo--my-controller-integer-val-value" => "42",
        "foo--my-controller-float-val-value" => "3.14159",
        "foo--my-controller-bool-true-value" => "true",
        "foo--my-controller-bool-false-value" => "false",
        "foo--my-controller-null-val-value" => "",
        "foo--my-controller-array-val-value" => '[1,"two",true,null]',
        "foo--my-controller-hash-val-value" => '{"key1":"value1","key2":2,"key3":false}'
      }
      assert_equal expected, collection.to_h
    end

    def test_unicode_and_special_characters_in_values
      # Test values with unicode and special characters
      unicode_value = StimulusValue.new(:message, "Hello 世界! 🌍", implied_controller: @implied_controller)
      json_string = StimulusValue.new(:json_data, '{"name": "test", "emoji": "😀"}', implied_controller: @implied_controller)
      special_chars = StimulusValue.new(:special, "Line 1\nLine 2\tTabbed", implied_controller: @implied_controller)

      collection = StimulusValueCollection.new([
        unicode_value,
        json_string,
        special_chars
      ])

      result = collection.to_h

      assert_equal "Hello 世界! 🌍", result["foo--my-controller-message-value"]
      assert_equal '{"name": "test", "emoji": "😀"}', result["foo--my-controller-json-data-value"]
      assert_equal "Line 1\nLine 2\tTabbed", result["foo--my-controller-special-value"]
    end
  end
end
