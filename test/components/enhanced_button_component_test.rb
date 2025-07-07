# frozen_string_literal: true

require "test_helper"

class Greeters::EnhancedButtonComponentTest < ViewComponent::TestCase
  def test_can_be_instantiated
    component = Greeters::EnhancedButtonComponent.new
    assert_instance_of Greeters::EnhancedButtonComponent, component
  end

  def test_stimulus_dsl_attributes_collected
    dsl_attrs = Greeters::EnhancedButtonComponent.stimulus_dsl_attributes
    
    assert_includes dsl_attrs[:stimulus_actions], :click
    assert_includes dsl_attrs[:stimulus_actions], :toggle_loading
    assert_includes dsl_attrs[:stimulus_targets], :button
    assert_includes dsl_attrs[:stimulus_targets], :spinner
    assert_equal "opacity-50 cursor-not-allowed", dsl_attrs[:stimulus_classes][:loading]
    assert_equal "text-green-500", dsl_attrs[:stimulus_classes][:success]
  end

  def test_dsl_includes_expected_attributes
    dsl_attrs = Greeters::EnhancedButtonComponent.stimulus_dsl_attributes
    
    # Should include values that will be mapped from props
    assert_includes dsl_attrs[:stimulus_values_from_props], :text
    assert_includes dsl_attrs[:stimulus_values_from_props], :loading
    
    # Should include explicit classes
    assert_equal "text-red-500", dsl_attrs[:stimulus_classes][:error]
  end

  def test_dsl_value_prop_mapping
    component = Greeters::EnhancedButtonComponent.new(text: "Test")
    
    # Test DSL prop mapping
    resolved_values = component.send(:resolve_values_from_props, [:text, :missing])
    assert_equal "Test", resolved_values[:text]
    assert_empty resolved_values.reject { |k, v| v.nil? }.except(:text) # missing prop doesn't exist
  end

  def test_dsl_and_root_element_merging
    component = Greeters::EnhancedButtonComponent.new(text: "From Prop")
    
    # This tests the merging logic in prepare_component_attributes
    component.send(:prepare_component_attributes)
    
    # The component should have stimulus data attributes from DSL and root_element_attributes
    data_attrs = component.send(:stimulus_data_attributes)
    
    # Should include controller (from StimulusComponent default)
    assert data_attrs.key?("controller"), "Should have a controller attribute"
    
    # Should include values from DSL auto-mapped to props
    text_value_key = data_attrs.keys.find { |k| k.include?("text-value") }
    assert text_value_key, "Should have a text-value data attribute. Available keys: #{data_attrs.keys}"
    assert_equal "From Prop", data_attrs[text_value_key]
  end

  def test_renders_with_merged_attributes
    component = Greeters::EnhancedButtonComponent.new(text: "Test Button", loading: true)
    
    render_inline(component)
    
    # Should render button element
    assert_selector "button"
    
    # Should have stimulus controller
    assert_selector "button[data-controller*='enhanced-button-component']"
    
    # Should have stimulus values from DSL auto-mapped to props
    assert_selector "button[data-greeters--enhanced-button-component-text-value='Test Button']"
    assert_selector "button[data-greeters--enhanced-button-component-loading-value='true']"
    
    # Should have stimulus classes from DSL
    assert_selector "button[data-greeters--enhanced-button-component-loading-class='opacity-50 cursor-not-allowed']"
    
    # Should have content
    assert_text "Test Button"
  end
end