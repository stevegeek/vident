require "test_helper"

module Vident
  class StimulusDataAttributeBuilderTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
    end

    def test_empty_builder
      builder = StimulusDataAttributeBuilder.new
      result = builder.build
      assert_equal({}, result)
    end

    def test_single_controller
      controller = StimulusController.new("my_controller", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(controllers: [controller])
      result = builder.build
      assert_equal({"controller" => "my-controller"}, result)
    end

    def test_multiple_controllers
      controller1 = StimulusController.new("my_controller", implied_controller: @implied_controller)
      controller2 = StimulusController.new("other_controller", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(controllers: [controller1, controller2])
      result = builder.build
      assert_equal({"controller" => "my-controller other-controller"}, result)
    end

    def test_single_action
      action = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(actions: [action])
      result = builder.build
      assert_equal({"action" => "foo--my-controller#myAction"}, result)
    end

    def test_multiple_actions
      action1 = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      action2 = StimulusAction.new(:click, :other_action, implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(actions: [action1, action2])
      result = builder.build
      assert_equal({"action" => "foo--my-controller#myAction click->foo--my-controller#otherAction"}, result)
    end

    def test_single_target
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(targets: [target])
      result = builder.build
      assert_equal({"foo--my-controller-target" => "myTarget"}, result)
    end

    def test_multiple_targets
      target1 = StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      target2 = StimulusTarget.new(:other_target, implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(targets: [target1, target2])
      result = builder.build
      # Since both targets use the same data attribute name, they should be merged
      assert_equal("myTarget otherTarget", result["foo--my-controller-target"])
    end

    def test_single_outlet
      outlet = StimulusOutlet.new(:user_status, ".online-user", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(outlets: [outlet])
      result = builder.build
      assert_equal({"foo--my-controller-user-status-outlet" => ".online-user"}, result)
    end

    def test_multiple_outlets
      outlet1 = StimulusOutlet.new(:user_status, ".online-user", implied_controller: @implied_controller)
      outlet2 = StimulusOutlet.new(:chat_status, ".chat-active", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(outlets: [outlet1, outlet2])
      result = builder.build
      expected = {
        "foo--my-controller-user-status-outlet" => ".online-user",
        "foo--my-controller-chat-status-outlet" => ".chat-active"
      }
      assert_equal(expected, result)
    end

    def test_single_value
      value = StimulusValue.new(:url, "https://example.com", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(values: [value])
      result = builder.build
      assert_equal({"foo--my-controller-url-value" => "https://example.com"}, result)
    end

    def test_multiple_values
      value1 = StimulusValue.new(:url, "https://example.com", implied_controller: @implied_controller)
      value2 = StimulusValue.new(:timeout, 5000, implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(values: [value1, value2])
      result = builder.build
      expected = {
        "foo--my-controller-url-value" => "https://example.com",
        "foo--my-controller-timeout-value" => "5000"
      }
      assert_equal(expected, result)
    end

    def test_single_class
      css_class = StimulusClass.new(:loading, "spinner active", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(classes: [css_class])
      result = builder.build
      assert_equal({"foo--my-controller-loading-class" => "spinner active"}, result)
    end

    def test_multiple_classes
      class1 = StimulusClass.new(:loading, "spinner active", implied_controller: @implied_controller)
      class2 = StimulusClass.new(:error, "alert danger", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(classes: [class1, class2])
      result = builder.build
      expected = {
        "foo--my-controller-loading-class" => "spinner active",
        "foo--my-controller-error-class" => "alert danger"
      }
      assert_equal(expected, result)
    end

    def test_mixed_collections
      actions = [
        StimulusAction.new(:my_action, implied_controller: @implied_controller),
        StimulusAction.new(:click, :other_action, implied_controller: @implied_controller)
      ]
      targets = [
        StimulusTarget.new(:my_target, implied_controller: @implied_controller)
      ]

      builder = StimulusDataAttributeBuilder.new(actions: actions, targets: targets)
      result = builder.build
      expected = {
        "action" => "foo--my-controller#myAction click->foo--my-controller#otherAction",
        "foo--my-controller-target" => "myTarget"
      }
      assert_equal(expected, result)
    end

    def test_complete_stimulus_setup
      builder = StimulusDataAttributeBuilder.new(
        controllers: [StimulusController.new("my_controller", implied_controller: @implied_controller)],
        actions: [StimulusAction.new(:click, :submit, implied_controller: @implied_controller)],
        targets: [StimulusTarget.new(:form, implied_controller: @implied_controller)],
        outlets: [StimulusOutlet.new(:status, ".status-bar", implied_controller: @implied_controller)],
        values: [StimulusValue.new(:endpoint, "/api/submit", implied_controller: @implied_controller)],
        classes: [StimulusClass.new(:loading, "loading", implied_controller: @implied_controller)]
      )

      result = builder.build
      expected = {
        "controller" => "my-controller",
        "action" => "click->foo--my-controller#submit",
        "foo--my-controller-target" => "form",
        "foo--my-controller-status-outlet" => ".status-bar",
        "foo--my-controller-endpoint-value" => "/api/submit",
        "foo--my-controller-loading-class" => "loading"
      }
      assert_equal(expected, result)
    end

    def test_array_wrapping
      # Test that single items are wrapped in arrays properly
      controller = StimulusController.new("single_controller", implied_controller: @implied_controller)
      action = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)

      builder = StimulusDataAttributeBuilder.new(
        controllers: controller,
        actions: action,
        targets: target
      )

      result = builder.build
      expected = {
        "controller" => "single-controller",
        "action" => "foo--my-controller#myAction",
        "foo--my-controller-target" => "myTarget"
      }
      assert_equal(expected, result)
    end

    def test_single_controller_with_nested_path
      stimulus_controller = StimulusController.new("path/to/my_controller", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(controllers: [stimulus_controller])
      result = builder.build
      assert_equal({"controller" => "path--to--my-controller"}, result)
    end

    def test_multiple_stimulus_controller_objects
      controller1 = StimulusController.new("my_controller", implied_controller: @implied_controller)
      controller2 = StimulusController.new("other_controller", implied_controller: @implied_controller)

      builder = StimulusDataAttributeBuilder.new(controllers: [controller1, controller2])
      result = builder.build
      assert_equal({"controller" => "my-controller other-controller"}, result)
    end

    def test_single_stimulus_controller_object
      stimulus_controller = StimulusController.new("path/to/my_controller", implied_controller: @implied_controller)
      builder = StimulusDataAttributeBuilder.new(controllers: stimulus_controller)
      result = builder.build
      assert_equal({"controller" => "path--to--my-controller"}, result)
    end

    def test_complex_scenario_with_multiple_controllers_and_mixed_attributes
      # Create multiple controllers with different patterns
      main_controller = StimulusController.new("form_controller", implied_controller: @implied_controller)
      modal_controller = StimulusController.new("modals/popup_controller", implied_controller: @implied_controller)
      validation_controller = StimulusController.new(implied_controller: @implied_controller_path) # Uses implied controller

      # Create actions with different controller contexts
      form_actions = [
        StimulusAction.new(:submit, implied_controller: @implied_controller),
        StimulusAction.new(:click, :reset, implied_controller: @implied_controller),
        StimulusAction.new("modals/popup_controller", :open, implied_controller: @implied_controller)
      ]

      # Create targets for different controllers
      targets = [
        StimulusTarget.new(:form, implied_controller: @implied_controller),
        StimulusTarget.new("modals/popup_controller", :dialog, implied_controller: @implied_controller),
        StimulusTarget.new(:error_message, implied_controller: @implied_controller)
      ]

      # Create outlets with component references
      outlets = [
        StimulusOutlet.new(:notification, ".notification-area", implied_controller: @implied_controller),
        StimulusOutlet.new(:user_profile, "#user-profile", implied_controller: @implied_controller)
      ]

      # Create values with different data types
      values = [
        StimulusValue.new(:endpoint, "/api/forms", implied_controller: @implied_controller),
        StimulusValue.new(:timeout, 5000, implied_controller: @implied_controller),
        StimulusValue.new(:enabled, true, implied_controller: @implied_controller),
        StimulusValue.new("modals/popup_controller", :animation_duration, 300, implied_controller: @implied_controller)
      ]

      # Create CSS classes for different states
      classes = [
        StimulusClass.new(:loading, "spinner animate-spin", implied_controller: @implied_controller),
        StimulusClass.new(:error, "border-red-500 bg-red-50", implied_controller: @implied_controller),
        StimulusClass.new("modals/popup_controller", :open, "opacity-100 scale-100", implied_controller: @implied_controller)
      ]

      builder = StimulusDataAttributeBuilder.new(
        controllers: [main_controller, modal_controller, validation_controller],
        actions: form_actions,
        targets: targets,
        outlets: outlets,
        values: values,
        classes: classes
      )

      result = builder.build

      expected = {
        "controller" => "form-controller modals--popup-controller foo--my-controller",
        "action" => "foo--my-controller#submit click->foo--my-controller#reset modals--popup-controller#open",
        "foo--my-controller-target" => "form errorMessage",
        "modals--popup-controller-target" => "dialog",
        "foo--my-controller-notification-outlet" => ".notification-area",
        "foo--my-controller-user-profile-outlet" => "#user-profile",
        "foo--my-controller-endpoint-value" => "/api/forms",
        "foo--my-controller-timeout-value" => "5000",
        "foo--my-controller-enabled-value" => "true",
        "modals--popup-controller-animation-duration-value" => "300",
        "foo--my-controller-loading-class" => "spinner animate-spin",
        "foo--my-controller-error-class" => "border-red-500 bg-red-50",
        "modals--popup-controller-open-class" => "opacity-100 scale-100"
      }

      assert_equal expected, result
    end

    def test_cross_controller_references_and_namespacing
      # Test scenario where components reference each other across different namespaces
      admin_controller = StimulusController.new("admin/dashboard_controller", implied_controller: @implied_controller)
      ui_controller = StimulusController.new("ui/dropdown_controller", implied_controller: @implied_controller)

      # Actions that cross-reference different controllers
      cross_actions = [
        StimulusAction.new("admin/dashboard_controller", :refresh, implied_controller: @implied_controller),
        StimulusAction.new(:mouseenter, "ui/dropdown_controller", :show, implied_controller: @implied_controller),
        StimulusAction.new(:mouseleave, "ui/dropdown_controller", :hide, implied_controller: @implied_controller)
      ]

      # Outlets that reference external components
      cross_outlets = [
        StimulusOutlet.new("admin/dashboard_controller", :sidebar, ".sidebar-component", implied_controller: @implied_controller),
        StimulusOutlet.new("ui/dropdown_controller", :menu_items, "[data-menu-item]", implied_controller: @implied_controller)
      ]

      # Values for cross-controller communication
      cross_values = [
        StimulusValue.new("admin/dashboard_controller", :refresh_interval, 30000, implied_controller: @implied_controller),
        StimulusValue.new("ui/dropdown_controller", :position, "bottom-left", implied_controller: @implied_controller)
      ]

      builder = StimulusDataAttributeBuilder.new(
        controllers: [admin_controller, ui_controller],
        actions: cross_actions,
        outlets: cross_outlets,
        values: cross_values
      )

      result = builder.build

      expected = {
        "controller" => "admin--dashboard-controller ui--dropdown-controller",
        "action" => "admin--dashboard-controller#refresh mouseenter->ui--dropdown-controller#show mouseleave->ui--dropdown-controller#hide",
        "admin--dashboard-controller-sidebar-outlet" => ".sidebar-component",
        "ui--dropdown-controller-menu-items-outlet" => "[data-menu-item]",
        "admin--dashboard-controller-refresh-interval-value" => "30000",
        "ui--dropdown-controller-position-value" => "bottom-left"
      }

      assert_equal expected, result
    end

    def test_edge_cases_with_special_characters_and_naming
      # Test with snake_case to kebab-case conversion and special naming scenarios
      special_controller = StimulusController.new("special_chars/multi_word_controller", implied_controller: @implied_controller)

      # Test snake_case to camelCase conversion for actions and targets
      special_actions = [
        StimulusAction.new(:handle_form_submission, implied_controller: @implied_controller),
        StimulusAction.new(:keydown, :handle_escape_key, implied_controller: @implied_controller)
      ]

      special_targets = [
        StimulusTarget.new(:error_message_container, implied_controller: @implied_controller),
        StimulusTarget.new(:submit_button_element, implied_controller: @implied_controller)
      ]

      special_values = [
        StimulusValue.new(:api_endpoint_url, "https://api.example.com/v1/users", implied_controller: @implied_controller),
        StimulusValue.new(:max_retry_attempts, 3, implied_controller: @implied_controller),
        StimulusValue.new(:user_preferences, {theme: "dark", lang: "en"}, implied_controller: @implied_controller)
      ]

      special_classes = [
        StimulusClass.new(:loading_state, "opacity-50 pointer-events-none", implied_controller: @implied_controller),
        StimulusClass.new(:validation_error, "border-2 border-red-500", implied_controller: @implied_controller)
      ]

      builder = StimulusDataAttributeBuilder.new(
        controllers: [special_controller],
        actions: special_actions,
        targets: special_targets,
        values: special_values,
        classes: special_classes
      )

      result = builder.build

      expected = {
        "controller" => "special-chars--multi-word-controller",
        "action" => "foo--my-controller#handleFormSubmission keydown->foo--my-controller#handleEscapeKey",
        "foo--my-controller-target" => "errorMessageContainer submitButtonElement",
        "foo--my-controller-api-endpoint-url-value" => "https://api.example.com/v1/users",
        "foo--my-controller-max-retry-attempts-value" => "3",
        "foo--my-controller-user-preferences-value" => '{"theme":"dark","lang":"en"}',
        "foo--my-controller-loading-state-class" => "opacity-50 pointer-events-none",
        "foo--my-controller-validation-error-class" => "border-2 border-red-500"
      }

      assert_equal expected, result
    end

    def test_duplicate_handling_and_merging
      # Test how the builder handles duplicate attribute names and merging

      # Multiple targets with same controller should merge
      duplicate_targets = [
        StimulusTarget.new(:field, implied_controller: @implied_controller),
        StimulusTarget.new(:input, implied_controller: @implied_controller),
        StimulusTarget.new(:field, implied_controller: @implied_controller) # Duplicate
      ]

      # Multiple actions should concatenate
      duplicate_actions = [
        StimulusAction.new(:submit, implied_controller: @implied_controller),
        StimulusAction.new(:click, :validate, implied_controller: @implied_controller),
        StimulusAction.new(:submit, implied_controller: @implied_controller) # Duplicate
      ]

      builder = StimulusDataAttributeBuilder.new(
        actions: duplicate_actions,
        targets: duplicate_targets
      )

      result = builder.build

      expected = {
        "action" => "foo--my-controller#submit click->foo--my-controller#validate foo--my-controller#submit",
        "foo--my-controller-target" => "field input field"
      }

      assert_equal expected, result
    end

    def test_empty_and_nil_handling
      # Test that empty arrays and nil values are handled gracefully
      builder = StimulusDataAttributeBuilder.new(
        controllers: [],
        actions: nil,
        targets: [StimulusTarget.new(:valid_target, implied_controller: @implied_controller)],
        outlets: [],
        values: nil,
        classes: []
      )

      result = builder.build

      expected = {
        "foo--my-controller-target" => "validTarget"
      }

      assert_equal expected, result
    end

    def test_complex_real_world_form_scenario
      # Simulate a real-world complex form with validation, submission, and UI feedback

      only_implied_controller = StimulusController.new(implied_controller: @implied_controller_path)

      # Main form controller
      form_controller = StimulusController.new("forms/advanced_form_controller", implied_controller: @implied_controller)

      # Validation controller for real-time validation
      validation_controller = StimulusController.new("validation/field_validator_controller", implied_controller: @implied_controller)

      # UI feedback controller for loading states and notifications
      ui_controller = StimulusController.new("ui/feedback_controller", implied_controller: @implied_controller)

      # Form interaction actions
      form_actions = [
        StimulusAction.new("forms/advanced_form_controller", :submit, implied_controller: @implied_controller),
        StimulusAction.new(:input, "validation/field_validator_controller", :validate_field, implied_controller: @implied_controller),
        StimulusAction.new(:focus, "ui/feedback_controller", :clear_errors, implied_controller: @implied_controller),
        StimulusAction.new(:ajax_success, "ui/feedback_controller", :show_success, implied_controller: @implied_controller),
        StimulusAction.new(:ajax_error, "ui/feedback_controller", :show_error, implied_controller: @implied_controller)
      ]

      # Form elements as targets
      form_targets = [
        StimulusTarget.new("forms/advanced_form_controller", :form, implied_controller: @implied_controller),
        StimulusTarget.new("forms/advanced_form_controller", :submit_button, implied_controller: @implied_controller),
        StimulusTarget.new("validation/field_validator_controller", :error_container, implied_controller: @implied_controller),
        StimulusTarget.new("ui/feedback_controller", :notification_area, implied_controller: @implied_controller)
      ]

      # External component outlets
      form_outlets = [
        StimulusOutlet.new("forms/advanced_form_controller", :progress_indicator, ".form-progress", implied_controller: @implied_controller),
        StimulusOutlet.new("ui/feedback_controller", :toast_notifications, "#toast-container", implied_controller: @implied_controller)
      ]

      # Configuration values
      form_values = [
        StimulusValue.new("forms/advanced_form_controller", :submit_url, "/api/forms/submit", implied_controller: @implied_controller),
        StimulusValue.new("forms/advanced_form_controller", :method, "POST", implied_controller: @implied_controller),
        StimulusValue.new("validation/field_validator_controller", :debounce_delay, 300, implied_controller: @implied_controller),
        StimulusValue.new("validation/field_validator_controller", :required_fields, ["email", "name"], implied_controller: @implied_controller),
        StimulusValue.new(:auto_hide_delay, 5000, implied_controller: @implied_controller),
        StimulusValue.new("ui/feedback_controller", :show_progress, true, implied_controller: @implied_controller)
      ]

      # CSS classes for different states
      form_classes = [
        StimulusClass.new("forms/advanced_form_controller", :submitting, "opacity-75 pointer-events-none", implied_controller: @implied_controller),
        StimulusClass.new("forms/advanced_form_controller", :success, "border-green-500 bg-green-50", implied_controller: @implied_controller),
        StimulusClass.new("validation/field_validator_controller", :error, "border-red-500 text-red-600", implied_controller: @implied_controller),
        StimulusClass.new("validation/field_validator_controller", :valid, "border-green-500 text-green-600", implied_controller: @implied_controller),
        StimulusClass.new("ui/feedback_controller", :notification, "transform transition-all duration-300", implied_controller: @implied_controller)
      ]

      builder = StimulusDataAttributeBuilder.new(
        controllers: [only_implied_controller, form_controller, validation_controller, ui_controller],
        actions: form_actions,
        targets: form_targets,
        outlets: form_outlets,
        values: form_values,
        classes: form_classes
      )

      result = builder.build

      expected = {
        "controller" => "foo--my-controller forms--advanced-form-controller validation--field-validator-controller ui--feedback-controller",
        "action" => "forms--advanced-form-controller#submit input->validation--field-validator-controller#validateField focus->ui--feedback-controller#clearErrors ajax_success->ui--feedback-controller#showSuccess ajax_error->ui--feedback-controller#showError",
        "forms--advanced-form-controller-target" => "form submitButton",
        "validation--field-validator-controller-target" => "errorContainer",
        "ui--feedback-controller-target" => "notificationArea",
        "forms--advanced-form-controller-progress-indicator-outlet" => ".form-progress",
        "ui--feedback-controller-toast-notifications-outlet" => "#toast-container",
        "forms--advanced-form-controller-submit-url-value" => "/api/forms/submit",
        "forms--advanced-form-controller-method-value" => "POST",
        "validation--field-validator-controller-debounce-delay-value" => "300",
        "validation--field-validator-controller-required-fields-value" => '["email","name"]',
        "foo--my-controller-auto-hide-delay-value" => "5000",
        "ui--feedback-controller-show-progress-value" => "true",
        "forms--advanced-form-controller-submitting-class" => "opacity-75 pointer-events-none",
        "forms--advanced-form-controller-success-class" => "border-green-500 bg-green-50",
        "validation--field-validator-controller-error-class" => "border-red-500 text-red-600",
        "validation--field-validator-controller-valid-class" => "border-green-500 text-green-600",
        "ui--feedback-controller-notification-class" => "transform transition-all duration-300"
      }

      assert_equal expected, result
    end
  end
end
