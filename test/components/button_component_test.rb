# frozen_string_literal: true

require "test_helper"
require "vident"

class ButtonComponentTest < ViewComponent::TestCase
  def test_stimulus_identifier_matches_v1
    assert_equal "button_component", ::ButtonComponent.stimulus_identifier_path
    assert_equal "button-component", ::ButtonComponent.stimulus_identifier
  end

  def test_renders_button_with_default_text
    render_inline(::ButtonComponent.new)
    assert_selector "button"
    assert_selector "span[data-button-component-target='status']", text: "Click me"
    assert_selector "button[data-controller='button-component']"
  end

  def test_renders_button_with_custom_text
    render_inline(::ButtonComponent.new(text: "Save"))
    assert_selector "button"
    assert_selector "span[data-button-component-target='status']", text: "Save"
  end

  def test_renders_as_link_when_url_provided
    render_inline(::ButtonComponent.new(url: "/home", text: "Home"))
    assert_selector "a[href='/home']"
    assert_selector "span[data-button-component-target='status']", text: "Home"
    assert_selector "a[data-controller='button-component']"
  end

  def test_applies_primary_style_classes
    render_inline(::ButtonComponent.new(style: :primary))
    assert_selector "button.btn.btn-primary"
  end

  def test_applies_secondary_style_classes
    render_inline(::ButtonComponent.new(style: :secondary))
    assert_selector "button.btn.btn-secondary"
  end

  def test_includes_stimulus_data_attributes
    render_inline(::ButtonComponent.new(text: "Test", clicked_count: 5))
    assert_selector "button[data-controller='button-component']"
    assert_selector "button[data-action='click->button-component#handleClick']"
    assert_selector "button[data-button-component-clicked-count-value='5']"
    assert_selector "button[data-button-component-loading-duration-value='1000']"
    assert_selector "button[data-button-component-loading-class='opacity-50 cursor-wait']"
    assert_selector "span[data-button-component-target='status']", text: "Test"
  end

  def test_dynamic_values_resolved_from_procs
    # item_count / api_url procs evaluated at render time.
    render_inline(::ButtonComponent.new)
    assert_selector "button[data-button-component-item-count-value='0']"
    assert_selector "button[data-button-component-api-url-value='/']"
  end

  def test_dynamic_class_resolves_from_proc
    render_inline(::ButtonComponent.new)
    assert_selector "button[data-button-component-size-class='small']"
  end

  def test_component_has_unique_id
    render_inline(::ButtonComponent.new)
    assert_selector "button[id^='button-component-']"
  end
end
