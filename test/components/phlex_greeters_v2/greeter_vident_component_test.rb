# frozen_string_literal: true

require "test_helper"
require "vident2"

class PhlexGreetersV2GreeterVidentComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "phlex_greeters/greeter_vident_component",
      PhlexGreetersV2::GreeterVidentComponent.stimulus_identifier_path
    assert_equal "phlex-greeters--greeter-vident-component",
      PhlexGreetersV2::GreeterVidentComponent.stimulus_identifier
  end

  def test_renders_stimulus_controller_on_root
    html = PhlexGreetersV2::GreeterVidentComponent.new(cta: "Hi").call
    assert_includes html, 'data-controller="phlex-greeters--greeter-vident-component"'
  end

  def test_renders_cta_text_in_button
    html = PhlexGreetersV2::GreeterVidentComponent.new(cta: "Hello").call
    assert_match(/<button\b[^>]*>.*Hello.*<\/button>/m, html)
  end

  def test_input_has_two_targets_combined_in_one_attribute
    # `stimulus_targets(:name, :another_name).to_h` returns one entry
    # with space-joined values (targets merge under a single key).
    # Symbol target names are js-cased: `:another_name` -> `anotherName`.
    html = PhlexGreetersV2::GreeterVidentComponent.new(cta: "X").call
    assert_match(/<input\b[^>]*data-phlex-greeters--greeter-vident-component-target="name anotherName"/, html)
  end

  def test_button_has_actions_combined_in_one_attribute
    # `stimulus_actions(:greet, [:click, :another_action])` parses to
    # two Action entries joined into one data-action value.
    html = PhlexGreetersV2::GreeterVidentComponent.new(cta: "X").call
    assert_match(/<button\b[^>]*data-action="phlex-greeters--greeter-vident-component#greet click->phlex-greeters--greeter-vident-component#anotherAction"/, html)
  end

  def test_output_span_has_single_target_attribute
    html = PhlexGreetersV2::GreeterVidentComponent.new(cta: "X").call
    assert_match(/<span\b[^>]*data-phlex-greeters--greeter-vident-component-target="output"/, html)
  end
end
