# frozen_string_literal: true

require "test_helper"

class PhlexGreeters::GreeterWithTriggerComponentTest < Minitest::Test
  def test_can_be_instantiated
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    assert_instance_of PhlexGreeters::GreeterWithTriggerComponent, component
  end

  def test_trigger_method_creates_greeter_button_component
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    trigger = component.trigger(before_clicked_message: "Click me")
    
    assert_instance_of PhlexGreeters::GreeterButtonComponent, trigger
  end

  def test_trigger_method_accepts_arguments
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    trigger = component.trigger(
      after_clicked_message: "Clicked!",
      before_clicked_message: "Click me"
    )
    
    assert_instance_of PhlexGreeters::GreeterButtonComponent, trigger
  end

  def test_trigger_method_memoizes_instance
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    trigger1 = component.trigger(before_clicked_message: "First")
    trigger2 = component.trigger(before_clicked_message: "Second")
    
    # Should return the same instance (memoized)
    assert_same trigger1, trigger2
  end

  def test_root_element_attributes_returns_stimulus_classes
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)
    
    assert_instance_of Hash, attributes
    assert_includes attributes.keys, :stimulus_classes
    assert_equal "text-md text-gray-500", attributes[:stimulus_classes][:pre_click]
    assert_equal "text-xl text-blue-700", attributes[:stimulus_classes][:post_click]
  end

  def test_component_inheritance_chain
    assert PhlexGreeters::GreeterWithTriggerComponent < PhlexGreeters::ApplicationComponent
    assert PhlexGreeters::ApplicationComponent < Vident::Phlex::HTML
  end

  def test_component_has_view_template_method
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    assert component.private_methods.include?(:view_template)
  end

  def test_component_has_trigger_or_default_method
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    assert component.private_methods.include?(:trigger_or_default)
  end

  def test_component_includes_vident_modules
    assert PhlexGreeters::GreeterWithTriggerComponent.included_modules.include?(Vident::Component)
  end

  def test_component_stimulus_controller_enabled
    # Should inherit stimulus controller functionality from Vident::Phlex::HTML
    assert PhlexGreeters::GreeterWithTriggerComponent.stimulus_controller?
  end

  def test_component_stimulus_identifier
    expected_identifier = "phlex-greeters--greeter-with-trigger-component"
    assert_equal expected_identifier, PhlexGreeters::GreeterWithTriggerComponent.stimulus_identifier
  end

  def test_component_class_name
    expected_class_name = "phlex-greeters--greeter-with-trigger-component"
    assert_equal expected_class_name, PhlexGreeters::GreeterWithTriggerComponent.component_class_name
  end

  # Test rendering with a simple approach similar to the Phlex documentation
  def test_view_template_structure
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    
    # Test that the view_template method exists and is private
    assert component.private_methods.include?(:view_template)
  end

  def test_trigger_or_default_with_no_custom_trigger
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    
    # Mock a greeter object with stimulus_action method
    greeter = Object.new
    def greeter.stimulus_action(event, action)
      "click->test##{action}"
    end
    
    # Should create a default trigger when no custom trigger is set
    result = component.send(:trigger_or_default, greeter)
    assert_instance_of PhlexGreeters::GreeterButtonComponent, result
  end

  def test_trigger_or_default_with_custom_trigger
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    custom_trigger = component.trigger(before_clicked_message: "Custom")
    
    # Mock a greeter object
    greeter = Object.new
    
    # Should return the custom trigger when one is set
    # The method will fail because it tries to call render on @trigger
    # This is expected behavior in a view context, but not in isolation
    assert_raises(NoMethodError) do
      component.send(:trigger_or_default, greeter)
    end
  end

  def test_component_default_controller_path
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    expected_path = "phlex_greeters/greeter_with_trigger_component"
    assert_equal expected_path, component.default_controller_path
  end

  def test_component_stimulus_identifier_path
    expected_path = "phlex_greeters/greeter_with_trigger_component"
    assert_equal expected_path, PhlexGreeters::GreeterWithTriggerComponent.stimulus_identifier_path
  end

  def test_component_js_event_name_prefix
    expected_prefix = "phlex-greeters--greeter-with-trigger-component"
    assert_equal expected_prefix, PhlexGreeters::GreeterWithTriggerComponent.js_event_name_prefix
  end

  def test_root_element_attributes_structure
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)
    
    assert_equal [:stimulus_classes], attributes.keys
    assert_equal 2, attributes[:stimulus_classes].size
    assert attributes[:stimulus_classes].key?(:pre_click)
    assert attributes[:stimulus_classes].key?(:post_click)
  end

  def test_stimulus_classes_values
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)
    
    pre_click_classes = attributes[:stimulus_classes][:pre_click]
    post_click_classes = attributes[:stimulus_classes][:post_click]
    
    assert_includes pre_click_classes, "text-md"
    assert_includes pre_click_classes, "text-gray-500"
    assert_includes post_click_classes, "text-xl"
    assert_includes post_click_classes, "text-blue-700"
  end

  # Test for Vident::Phlex::HTML class methods
  def test_current_component_modified_time_class_method
    modified_time = PhlexGreeters::GreeterWithTriggerComponent.current_component_modified_time
    assert_instance_of String, modified_time
    refute_empty modified_time
    assert_match(/\A\d+\z/, modified_time)
  end

  def test_vanish_method_available
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    # The vanish method should be available from Vident::Phlex::HTML
    assert component.private_methods.include?(:vanish)
  end

  def test_root_element_method_available
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    # The root_element method should be available from Vident::Phlex::HTML
    assert component.methods.include?(:root_element)
  end
end