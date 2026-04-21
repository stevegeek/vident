# frozen_string_literal: true

require "test_helper"
require "vident"

class GreetersGreeterButtonComponentTest < ViewComponent::TestCase
  def test_stimulus_identifier_matches_v1
    assert_equal "greeters/greeter_button_component",
      Greeters::GreeterButtonComponent.stimulus_identifier_path
    assert_equal "greeters--greeter-button-component",
      Greeters::GreeterButtonComponent.stimulus_identifier
  end

  def test_renders_button_with_default_messages
    render_inline(Greeters::GreeterButtonComponent.new)
    assert_selector "button", text: "Greet"
  end

  def test_custom_before_message_is_rendered_as_content
    render_inline(Greeters::GreeterButtonComponent.new(before_clicked_message: "Wave"))
    assert_selector "button", text: "Wave"
  end

  def test_stimulus_action_from_root_element_attributes
    render_inline(Greeters::GreeterButtonComponent.new)
    assert_selector "button[data-action='greeters--greeter-button-component#changeMessage']"
  end

  def test_stimulus_values_from_root_element_attributes
    render_inline(Greeters::GreeterButtonComponent.new(
      before_clicked_message: "Start",
      after_clicked_message: "Done"
    ))
    assert_selector "button[data-greeters--greeter-button-component-before-clicked-message-value='Start']"
    assert_selector "button[data-greeters--greeter-button-component-after-clicked-message-value='Done']"
  end

  def test_stimulus_controller_attached
    render_inline(Greeters::GreeterButtonComponent.new)
    assert_selector "button[data-controller='greeters--greeter-button-component']"
  end

  def test_html_options_class_applied_to_button
    render_inline(Greeters::GreeterButtonComponent.new)
    assert_selector "button.ml-4.whitespace-no-wrap.bg-blue-500.rounded"
  end
end
