# frozen_string_literal: true

require "test_helper"
require "vident"

class PhlexGreetersGreeterButtonComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "phlex_greeters/greeter_button_component",
      PhlexGreeters::GreeterButtonComponent.stimulus_identifier_path
    assert_equal "phlex-greeters--greeter-button-component",
      PhlexGreeters::GreeterButtonComponent.stimulus_identifier
  end

  def test_renders_button_with_default_messages
    html = PhlexGreeters::GreeterButtonComponent.new.call
    assert_match(/<button\b/, html)
    assert_includes html, "Greet"
  end

  def test_stimulus_controller_attached
    html = PhlexGreeters::GreeterButtonComponent.new.call
    assert_includes html, 'data-controller="phlex-greeters--greeter-button-component"'
  end

  def test_stimulus_action_from_root_element_attributes
    html = PhlexGreeters::GreeterButtonComponent.new.call
    assert_includes html, 'data-action="phlex-greeters--greeter-button-component#changeMessage"'
  end

  def test_stimulus_values_from_root_element_attributes
    html = PhlexGreeters::GreeterButtonComponent.new(
      before_clicked_message: "Start",
      after_clicked_message: "Done"
    ).call
    assert_includes html, 'data-phlex-greeters--greeter-button-component-before-clicked-message-value="Start"'
    assert_includes html, 'data-phlex-greeters--greeter-button-component-after-clicked-message-value="Done"'
  end

  def test_custom_before_message_is_rendered_as_content
    html = PhlexGreeters::GreeterButtonComponent.new(before_clicked_message: "Wave").call
    assert_includes html, "Wave"
  end
end
