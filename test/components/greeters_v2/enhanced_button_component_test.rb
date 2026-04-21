# frozen_string_literal: true

require "test_helper"
require "vident2"

class GreetersV2EnhancedButtonComponentTest < ViewComponent::TestCase
  def test_stimulus_identifier_matches_v1
    assert_equal "greeters/enhanced_button_component",
      GreetersV2::EnhancedButtonComponent.stimulus_identifier_path
    assert_equal "greeters--enhanced-button-component",
      GreetersV2::EnhancedButtonComponent.stimulus_identifier
  end

  def test_can_be_instantiated
    component = GreetersV2::EnhancedButtonComponent.new
    assert_instance_of GreetersV2::EnhancedButtonComponent, component
  end

  def test_renders_with_merged_attributes
    render_inline(GreetersV2::EnhancedButtonComponent.new(text: "Test Button", loading: true))
    assert_selector "button"
    assert_selector "button[data-controller*='enhanced-button-component']"
    assert_selector "button[data-greeters--enhanced-button-component-text-value='Test Button']"
    assert_selector "button[data-greeters--enhanced-button-component-loading-value='true']"
    assert_selector "button[data-greeters--enhanced-button-component-loading-class='opacity-50 cursor-not-allowed']"
    assert_text "Test Button"
  end

  def test_dsl_actions_emitted_on_root
    # DSL form `actions :click, :toggle_loading` parses as two separate
    # method-on-implied-controller entries (no explicit event prefix).
    render_inline(GreetersV2::EnhancedButtonComponent.new)
    assert_selector "button[data-action*='greeters--enhanced-button-component#click']"
    assert_selector "button[data-action*='greeters--enhanced-button-component#toggleLoading']"
  end

  def test_spinner_target_rendered_via_as_stimulus_target
    render_inline(GreetersV2::EnhancedButtonComponent.new)
    assert_selector "span[data-greeters--enhanced-button-component-target='spinner']"
  end

  def test_stimulus_classes_rendered
    render_inline(GreetersV2::EnhancedButtonComponent.new)
    assert_selector "button[data-greeters--enhanced-button-component-success-class='text-green-500']"
    assert_selector "button[data-greeters--enhanced-button-component-error-class='text-red-500']"
  end
end
