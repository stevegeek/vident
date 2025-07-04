# frozen_string_literal: true

require "test_helper"

module Vident
  module ViewComponent
    class BaseTest < ::ViewComponent::TestCase
      def setup
        # Use the existing GreeterWithTriggerComponent which properly inherits from Vident::ViewComponent::Base
        @component = Greeters::GreeterWithTriggerComponent.new
      end

      # as_stimulus_target tests
      def test_as_stimulus_target_basic
        result = @component.as_stimulus_target(:button)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-target=\"button\"", result
      end

      def test_as_stimulus_target_with_custom_controller
        result = @component.as_stimulus_target("custom_controller", :input)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-custom-controller-target=\"input\"", result
      end

      def test_as_stimulus_target_snake_case_conversion
        result = @component.as_stimulus_target(:error_message)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-target=\"errorMessage\"", result
      end

      # as_stimulus_targets tests
      def test_as_stimulus_targets_multiple
        result = @component.as_stimulus_targets(:button, :input)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-target=\"button input\"", result
      end

      def test_as_stimulus_targets_empty
        result = @component.as_stimulus_targets
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "", result
      end

      # as_stimulus_action tests
      def test_as_stimulus_action_basic
        result = @component.as_stimulus_action(:click)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-action=\"greeters--greeter-with-trigger-component#click\"", result
      end

      def test_as_stimulus_action_with_event
        result = @component.as_stimulus_action(:submit, :save)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-action=\"submit->greeters--greeter-with-trigger-component#save\"", result
      end

      def test_as_stimulus_action_with_custom_controller
        result = @component.as_stimulus_action("custom_controller", :handle)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-action=\"custom-controller#handle\"", result
      end

      def test_as_stimulus_action_snake_case_conversion
        result = @component.as_stimulus_action(:handle_form_submit)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-action=\"greeters--greeter-with-trigger-component#handleFormSubmit\"", result
      end

      # as_stimulus_actions tests
      def test_as_stimulus_actions_multiple
        result = @component.as_stimulus_actions(:click, [:submit, :save])
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-action=\"greeters--greeter-with-trigger-component#click submit->greeters--greeter-with-trigger-component#save\"", result
      end

      def test_as_stimulus_actions_empty
        result = @component.as_stimulus_actions
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "", result
      end

      # as_stimulus_controller tests
      def test_as_stimulus_controller_basic
        result = @component.as_stimulus_controller("my_controller")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-controller=\"my-controller\"", result
      end

      def test_as_stimulus_controller_nested_path
        result = @component.as_stimulus_controller("forms/validation_controller")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-controller=\"forms--validation-controller\"", result
      end

      # as_stimulus_controllers tests
      def test_as_stimulus_controllers_multiple
        result = @component.as_stimulus_controllers("controller1", "controller2")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-controller=\"controller1 controller2\"", result
      end

      def test_as_stimulus_controllers_empty
        result = @component.as_stimulus_controllers
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "", result
      end

      # as_stimulus_value tests
      def test_as_stimulus_value_basic
        result = @component.as_stimulus_value(:url, "https://example.com")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-url-value=\"https://example.com\"", result
      end

      def test_as_stimulus_value_with_custom_controller
        result = @component.as_stimulus_value("api_controller", :endpoint, "/api/users")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-api-controller-endpoint-value=\"/api/users\"", result
      end

      def test_as_stimulus_value_number
        result = @component.as_stimulus_value(:timeout, 5000)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-timeout-value=\"5000\"", result
      end

      def test_as_stimulus_value_boolean
        result = @component.as_stimulus_value(:enabled, true)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-enabled-value=\"true\"", result
      end

      def test_as_stimulus_value_array
        result = @component.as_stimulus_value(:items, ["a", "b", "c"])
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-items-value=\"[&quot;a&quot;,&quot;b&quot;,&quot;c&quot;]\"", result
      end

      def test_as_stimulus_value_hash
        result = @component.as_stimulus_value(:config, {theme: "dark", lang: "en"})
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-config-value=\"{&quot;theme&quot;:&quot;dark&quot;,&quot;lang&quot;:&quot;en&quot;}\"", result
      end

      # as_stimulus_values tests
      def test_as_stimulus_values_hash_format
        result = @component.as_stimulus_values(url: "https://example.com", timeout: 5000)
        assert_instance_of ActiveSupport::SafeBuffer, result
        expected = "data-greeters--greeter-with-trigger-component-url-value=\"https://example.com\" data-greeters--greeter-with-trigger-component-timeout-value=\"5000\""
        assert_equal expected, result
      end

      def test_as_stimulus_values_empty
        result = @component.as_stimulus_values
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "", result
      end

      # as_stimulus_outlet tests
      def test_as_stimulus_outlet_basic
        result = @component.as_stimulus_outlet(:status, ".status-bar")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-status-outlet=\".status-bar\"", result
      end

      def test_as_stimulus_outlet_with_custom_controller
        result = @component.as_stimulus_outlet("ui_controller", :modal, "#modal-container")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-ui-controller-modal-outlet=\"#modal-container\"", result
      end

      def test_as_stimulus_outlet_snake_case_conversion
        result = @component.as_stimulus_outlet(:notification_area, ".notifications")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-notification-area-outlet=\".notifications\"", result
      end

      # as_stimulus_outlets tests
      def test_as_stimulus_outlets_multiple
        result = @component.as_stimulus_outlets([:status, ".status"], [:modal, "#modal"])
        assert_instance_of ActiveSupport::SafeBuffer, result
        expected = "data-greeters--greeter-with-trigger-component-status-outlet=\".status\" data-greeters--greeter-with-trigger-component-modal-outlet=\"#modal\""
        assert_equal expected, result
      end

      def test_as_stimulus_outlets_empty
        result = @component.as_stimulus_outlets
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "", result
      end

      # as_stimulus_class tests
      def test_as_stimulus_class_basic
        result = @component.as_stimulus_class(:loading, "spinner active")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-loading-class=\"spinner active\"", result
      end

      def test_as_stimulus_class_with_custom_controller
        result = @component.as_stimulus_class("ui_controller", :error, "text-red-500")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-ui-controller-error-class=\"text-red-500\"", result
      end

      def test_as_stimulus_class_snake_case_conversion
        result = @component.as_stimulus_class(:validation_error, "border-red-500")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-validation-error-class=\"border-red-500\"", result
      end

      # as_stimulus_classes tests
      def test_as_stimulus_classes_hash_format
        result = @component.as_stimulus_classes(loading: "spinner", error: "text-red-500")
        assert_instance_of ActiveSupport::SafeBuffer, result
        expected = "data-greeters--greeter-with-trigger-component-loading-class=\"spinner\" data-greeters--greeter-with-trigger-component-error-class=\"text-red-500\""
        assert_equal expected, result
      end

      def test_as_stimulus_classes_empty
        result = @component.as_stimulus_classes
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "", result
      end

      # HTML escaping tests
      def test_html_escaping_in_attribute_names
        result = @component.as_stimulus_target("controller/with_special_chars", :target_name)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-controller--with-special-chars-target=\"targetName\"", result
      end

      def test_html_escaping_in_attribute_values_quotes
        result = @component.as_stimulus_value(:message, 'Hello "World"')
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-message-value=\"Hello &quot;World&quot;\"", result
      end

      def test_html_escaping_in_attribute_values_single_quotes
        result = @component.as_stimulus_value(:message, "It's working")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-message-value=\"It&#39;s working\"", result
      end

      def test_html_escaping_in_outlet_selectors
        result = @component.as_stimulus_outlet(:container, "[data-role='container']")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-container-outlet=\"[data-role=&#39;container&#39;]\"", result
      end

      # Edge cases and error handling
      def test_as_methods_with_nil_values
        result = @component.as_stimulus_value(:optional, nil)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-optional-value=\"\"", result
      end

      def test_as_methods_with_empty_string_values
        result = @component.as_stimulus_value(:empty, "")
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-greeters--greeter-with-trigger-component-empty-value=\"\"", result
      end

      def test_as_methods_with_complex_nested_controller_paths
        result = @component.as_stimulus_action(:click, "admin--users--profile-controller", :edit)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert_equal "data-action=\"click->admin--users--profile-controller#edit\"", result
      end

      # Integration test using the existing GreeterWithTriggerComponent template
      def test_as_methods_work_in_actual_component_template
        # The GreeterWithTriggerComponent template already uses as_stimulus_target helper
        render_inline(@component)

        # Verify that the as_stimulus_target method is working in the actual template
        assert_selector "input[data-greeters--greeter-with-trigger-component-target='name']"
        assert_selector "span[data-greeters--greeter-with-trigger-component-target='output']"
      end

      # Test that as_ methods return HTML-safe strings
      def test_as_methods_return_html_safe_strings
        result = @component.as_stimulus_target(:button)
        assert result.html_safe?
        
        result = @component.as_stimulus_action(:click)
        assert result.html_safe?
        
        result = @component.as_stimulus_value(:url, "https://example.com")
        assert result.html_safe?
      end

      # Test to_data_attribute_string method behavior
      def test_to_data_attribute_string_private_method
        # This is a private method, but we can test its behavior indirectly
        result = @component.as_stimulus_targets(:first, :second)
        assert_instance_of ActiveSupport::SafeBuffer, result
        assert result.html_safe?
        # Should concatenate multiple data attributes with spaces
        assert_includes result, "data-greeters--greeter-with-trigger-component-target=\"first second\""
      end
    end
  end
end