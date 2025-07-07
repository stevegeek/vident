# frozen_string_literal: true

require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  def test_renders_button_with_default_text
    render_inline(ButtonComponent.new)
    
    assert_selector "button", text: "Click me"
    assert_selector "button[data-controller='button-component']"
  end
  
  def test_renders_button_with_custom_text
    render_inline(ButtonComponent.new(text: "Save"))
    
    assert_selector "button", text: "Save"
  end
  
  def test_renders_as_link_when_url_provided
    render_inline(ButtonComponent.new(url: "/home", text: "Home"))
    
    assert_selector "a[href='/home']", text: "Home"
    assert_selector "a[data-controller='button-component']"
  end
  
  def test_applies_primary_style_classes
    render_inline(ButtonComponent.new(style: :primary))
    
    assert_selector "button.btn.btn-primary"
  end
  
  def test_applies_secondary_style_classes
    render_inline(ButtonComponent.new(style: :secondary))
    
    assert_selector "button.btn.btn-secondary"
  end
  
  def test_includes_stimulus_data_attributes
    render_inline(ButtonComponent.new(text: "Test", clicked_count: 5))
    
    assert_selector "button[data-controller='button-component']"
    assert_selector "button[data-action='click->button-component#handleClick']"
    assert_selector "button[data-button-component-clicked-count-value='5']"
    assert_selector "button[data-button-component-loading-duration-value='1000']"
    assert_selector "button[data-button-component-loading-class='opacity-50 cursor-wait']"
  end
  
  def test_component_has_unique_id
    component = ButtonComponent.new
    render_inline(component)
    
    assert_selector "button[id^='button-component-']"
  end
  
  def test_stimulus_dsl_attributes_configured_correctly
    dsl_attrs = ButtonComponent.stimulus_dsl_attributes
    
    assert_includes dsl_attrs[:stimulus_actions], [:click, :handle_click]
    assert_equal({ loading_duration: 1000 }, dsl_attrs[:stimulus_values])
    assert_equal([:clicked_count], dsl_attrs[:stimulus_values_from_props])
    assert_equal({ loading: "opacity-50 cursor-wait" }, dsl_attrs[:stimulus_classes])
  end
  
  def test_values_from_props_resolution
    component = ButtonComponent.new(clicked_count: 10)
    
    # Test the prop mapping
    values_from_props = component.class.stimulus_dsl_attributes[:stimulus_values_from_props]
    resolved_values = component.send(:resolve_values_from_props, values_from_props)
    
    assert_equal({ clicked_count: 10 }, resolved_values)
  end
end