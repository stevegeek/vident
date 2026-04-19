require "test_helper"

module Vident
  class StimulusActionTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
    end

    def test_single_symbol_argument
      action = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      assert_equal "foo--my-controller#myAction", action.to_s
      assert_nil action.event
      assert_equal "foo--my-controller", action.controller
      assert_equal "myAction", action.action
    end

    def test_single_string_argument_without_event
      action = StimulusAction.new("other--controller#someAction", implied_controller: @implied_controller)
      assert_equal "other--controller#someAction", action.to_s
      assert_nil action.event
      assert_equal "other--controller", action.controller
      assert_equal "someAction", action.action
    end

    def test_single_string_argument_with_event
      action = StimulusAction.new("click->other--controller#someAction", implied_controller: @implied_controller)
      assert_equal "click->other--controller#someAction", action.to_s
      assert_equal "click", action.event
      assert_equal "other--controller", action.controller
      assert_equal "someAction", action.action
    end

    def test_two_symbol_arguments
      action = StimulusAction.new(:click, :my_action, implied_controller: @implied_controller)
      assert_equal "click->foo--my-controller#myAction", action.to_s
      assert_equal "click", action.event
      assert_equal "foo--my-controller", action.controller
      assert_equal "myAction", action.action
    end

    def test_string_and_symbol_arguments
      action = StimulusAction.new("path/to/controller", :my_action, implied_controller: @implied_controller)
      assert_equal "path--to--controller#myAction", action.to_s
      assert_nil action.event
      assert_equal "path--to--controller", action.controller
      assert_equal "myAction", action.action
    end

    def test_three_arguments
      action = StimulusAction.new(:hover, "path/to/controller", :my_action, implied_controller: @implied_controller)
      assert_equal "hover->path--to--controller#myAction", action.to_s
      assert_equal "hover", action.event
      assert_equal "path--to--controller", action.controller
      assert_equal "myAction", action.action
    end

    def test_inspect
      action = StimulusAction.new(:click, :my_action, implied_controller: @implied_controller)
      inspect_result = action.inspect
      assert_includes inspect_result, "#<Vident::StimulusAction"
      assert_includes inspect_result, '"action"'
      assert_includes inspect_result, '"click->foo--my-controller#myAction"'
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusAction.new(implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusAction.new(:a, :b, :c, :d, implied_controller: @implied_controller)
      end
    end

    def test_invalid_argument_types
      assert_raises(ArgumentError) do
        StimulusAction.new(123, implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusAction.new(:click, 123, implied_controller: @implied_controller)
      end
    end

    def test_invalid_three_argument_types
      assert_raises(ArgumentError, /Invalid 'action' argument types \(3\)/) do
        StimulusAction.new(:click, :not_a_string_path, :target, implied_controller: @implied_controller)
      end
    end

    def test_descriptor_with_options
      descriptor = StimulusAction::Descriptor.new(
        event: :click,
        method: :submit,
        options: [:once, :prevent]
      )
      action = StimulusAction.new(descriptor, implied_controller: @implied_controller)
      assert_equal "click:once:prevent->foo--my-controller#submit", action.to_s
      assert_equal [:once, :prevent], action.options
    end

    def test_descriptor_with_keyboard_filter
      descriptor = StimulusAction::Descriptor.new(event: :keydown, method: :handle_key, keyboard: "ctrl+a")
      action = StimulusAction.new(descriptor, implied_controller: @implied_controller)
      assert_equal "keydown.ctrl+a->foo--my-controller#handleKey", action.to_s
    end

    def test_descriptor_with_window_target
      descriptor = StimulusAction::Descriptor.new(event: :resize, method: :on_resize, window: true)
      action = StimulusAction.new(descriptor, implied_controller: @implied_controller)
      assert_equal "resize@window->foo--my-controller#onResize", action.to_s
      assert action.window
    end

    def test_descriptor_with_cross_controller
      descriptor = StimulusAction::Descriptor.new(
        event: :click,
        method: :show,
        controller: "dialog/modal",
        options: [:prevent]
      )
      action = StimulusAction.new(descriptor, implied_controller: @implied_controller)
      assert_equal "click:prevent->dialog--modal#show", action.to_s
      assert_equal "dialog--modal", action.controller
    end

    def test_descriptor_without_event
      descriptor = StimulusAction::Descriptor.new(method: :submit)
      action = StimulusAction.new(descriptor, implied_controller: @implied_controller)
      assert_equal "foo--my-controller#submit", action.to_s
      assert_nil action.event
    end

    def test_descriptor_rejects_invalid_option
      descriptor = StimulusAction::Descriptor.new(event: :click, method: :x, options: [:bogus])
      assert_raises(ArgumentError, /Invalid action option/) do
        StimulusAction.new(descriptor, implied_controller: @implied_controller)
      end
    end

    def test_hash_form_is_sugar_for_descriptor
      action = StimulusAction.new(
        {event: :click, method: :submit, options: [:once, :prevent]},
        implied_controller: @implied_controller
      )
      assert_equal "click:once:prevent->foo--my-controller#submit", action.to_s
    end

    def test_hash_form_combined_modifiers
      action = StimulusAction.new(
        {event: :keydown, method: :on_key, keyboard: "esc", options: [:prevent], window: true},
        implied_controller: @implied_controller
      )
      assert_equal "keydown.esc:prevent@window->foo--my-controller#onKey", action.to_s
    end
  end
end
