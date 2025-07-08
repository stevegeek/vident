# frozen_string_literal: true

require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  def test_renders_button_with_default_text
    render_inline(ButtonComponent.new)
    
    assert_selector "button"
    assert_selector "span[data-button-component-target='status']", text: "Click me"
    assert_selector "button[data-controller='button-component']"
  end
  
  def test_renders_button_with_custom_text
    render_inline(ButtonComponent.new(text: "Save"))
    
    assert_selector "button"
    assert_selector "span[data-button-component-target='status']", text: "Save"
  end
  
  def test_renders_as_link_when_url_provided
    render_inline(ButtonComponent.new(url: "/home", text: "Home"))
    
    assert_selector "a[href='/home']"
    assert_selector "span[data-button-component-target='status']", text: "Home"
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
    assert_selector "span[data-button-component-target='status']", text: "Test"
  end
  
  def test_component_has_unique_id
    component = ButtonComponent.new
    render_inline(component)
    
    assert_selector "button[id^='button-component-']"
  end
  
  def test_stimulus_dsl_attributes_configured_correctly
    dsl_attrs = ButtonComponent.stimulus_dsl_attributes(ButtonComponent.new)
    
    assert_includes dsl_attrs[:stimulus_actions], [:click, :handle_click]
    # No targets defined in the stimulus block since the target is on a child element
    assert_nil dsl_attrs[:stimulus_targets]
    
    # Updated to include the dynamic values from procs
    expected_values = {
      loading_duration: 1000,
      item_count: 0,  # @items&.count || 0 evaluates to 0
      api_url: "/"    # Rails.application.routes.url_helpers.root_path
    }
    assert_equal expected_values, dsl_attrs[:stimulus_values]
    assert_equal([:clicked_count], dsl_attrs[:stimulus_values_from_props])
    
    # Updated to include the dynamic classes
    expected_classes = {
      loading: "opacity-50 cursor-wait",
      size: "small"  # (@items&.count || 0) > 10 ? "large" : "small" evaluates to "small"
    }
    assert_equal expected_classes, dsl_attrs[:stimulus_classes]
  end
  
  def test_values_from_props_resolution
    component = ButtonComponent.new(clicked_count: 10)
    
    # Test the prop mapping
    values_from_props = component.class.stimulus_dsl_attributes(component)[:stimulus_values_from_props]
    resolved_values = component.send(:resolve_values_from_props, values_from_props)
    
    assert_equal({ clicked_count: 10 }, resolved_values)
  end
end