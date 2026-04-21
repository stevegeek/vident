# frozen_string_literal: true

require "test_helper"
require "vident2"

class PhlexGreetersV2GreeterWithTriggerComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "phlex_greeters/greeter_with_trigger_component",
      PhlexGreetersV2::GreeterWithTriggerComponent.stimulus_identifier_path
    assert_equal "phlex-greeters--greeter-with-trigger-component",
      PhlexGreetersV2::GreeterWithTriggerComponent.stimulus_identifier
  end

  def test_trigger_memoises_instance
    component = PhlexGreetersV2::GreeterWithTriggerComponent.new
    t1 = component.trigger(before_clicked_message: "First")
    t2 = component.trigger(before_clicked_message: "Second")
    assert_same t1, t2
  end

  def test_trigger_returns_greeter_button_component
    component = PhlexGreetersV2::GreeterWithTriggerComponent.new
    trigger = component.trigger(before_clicked_message: "Click me")
    assert_instance_of PhlexGreetersV2::GreeterButtonComponent, trigger
  end

  def test_root_element_attributes_returns_stimulus_classes
    component = PhlexGreetersV2::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)
    assert_equal "text-md text-gray-500", attributes[:stimulus_classes][:pre_click]
    assert_equal "text-xl text-blue-700", attributes[:stimulus_classes][:post_click]
  end

  def test_renders_stimulus_controller_on_root
    html = PhlexGreetersV2::GreeterWithTriggerComponent.new.call
    assert_includes html, 'data-controller="phlex-greeters--greeter-with-trigger-component"'
  end

  def test_renders_stimulus_class_data_attributes_from_root_element_attributes
    html = PhlexGreetersV2::GreeterWithTriggerComponent.new.call
    assert_includes html, 'data-phlex-greeters--greeter-with-trigger-component-pre-click-class="text-md text-gray-500"'
    assert_includes html, 'data-phlex-greeters--greeter-with-trigger-component-post-click-class="text-xl text-blue-700"'
  end

  def test_renders_input_with_name_target
    html = PhlexGreetersV2::GreeterWithTriggerComponent.new.call
    assert_match(/<input\b[^>]*data-phlex-greeters--greeter-with-trigger-component-target="name"/, html)
  end

  def test_renders_output_span_with_inlined_stimulus_classes
    # `greeter.class_list_for_stimulus_classes(:pre_click)` inlines the
    # ClassMap CSS into the child's class list for the SSR render.
    html = PhlexGreetersV2::GreeterWithTriggerComponent.new.call
    assert_match(/<span\b[^>]*class="ml-4 text-md text-gray-500"/, html)
  end

  def test_renders_output_span_with_target
    html = PhlexGreetersV2::GreeterWithTriggerComponent.new.call
    assert_match(/<span\b[^>]*data-phlex-greeters--greeter-with-trigger-component-target="output"/, html)
  end
end
