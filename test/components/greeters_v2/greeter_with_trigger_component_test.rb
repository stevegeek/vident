# frozen_string_literal: true

require "test_helper"
require "vident2"

class GreetersV2GreeterWithTriggerComponentTest < ViewComponent::TestCase
  def test_stimulus_identifier_matches_v1
    assert_equal "greeters/greeter_with_trigger_component",
      GreetersV2::GreeterWithTriggerComponent.stimulus_identifier_path
    assert_equal "greeters--greeter-with-trigger-component",
      GreetersV2::GreeterWithTriggerComponent.stimulus_identifier
  end

  def test_renders_basic_structure
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "div"
    assert_selector "input[type='text']"
    assert_selector "span", text: "..."
    assert_selector "button"
  end

  def test_renders_default_trigger
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "button", text: "I'm the trigger! Click me to greet."
  end

  def test_renders_with_custom_trigger
    render_inline(GreetersV2::GreeterWithTriggerComponent.new) do |component|
      component.with_trigger(
        after_clicked_message: "Custom greeted!",
        before_clicked_message: "Custom greet"
      )
    end
    assert_selector "button", text: "Custom greet"
  end

  def test_input_has_stimulus_target
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "input[data-greeters--greeter-with-trigger-component-target='name']"
  end

  def test_output_span_has_stimulus_target
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "span[data-greeters--greeter-with-trigger-component-target='output']"
  end

  def test_output_span_has_stimulus_classes_inlined_via_class_list_helper
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "span.text-md.text-gray-500"
  end

  def test_default_trigger_has_stimulus_action
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "button[data-action*='greeters--greeter-with-trigger-component#greet']"
  end

  def test_root_has_stimulus_controller_data_attribute
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "div[data-controller='greeters--greeter-with-trigger-component']"
  end

  def test_root_has_stimulus_class_data_attributes_from_root_element_attributes
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "div[data-greeters--greeter-with-trigger-component-pre-click-class='text-md text-gray-500']"
    assert_selector "div[data-greeters--greeter-with-trigger-component-post-click-class='text-xl text-blue-700']"
  end

  def test_default_trigger_has_role_attribute
    render_inline(GreetersV2::GreeterWithTriggerComponent.new)
    assert_selector "button[role='button']"
  end
end
