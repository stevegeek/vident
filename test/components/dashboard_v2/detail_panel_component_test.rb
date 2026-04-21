# frozen_string_literal: true

require "test_helper"
require "vident2"

class DashboardV2DetailPanelComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "dashboard/detail_panel_component",
      DashboardV2::DetailPanelComponent.stimulus_identifier_path
    assert_equal "dashboard--detail-panel-component",
      DashboardV2::DetailPanelComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = DashboardV2::DetailPanelComponent.new.call
    assert_includes html, 'data-controller="dashboard--detail-panel-component"'
  end

  def test_release_value_is_stimulus_null_literal
    # StimulusNull serialises to the literal string "null" so Stimulus's
    # Object parser hands the JS side JSON `null` until the first selection.
    html = DashboardV2::DetailPanelComponent.new.call
    assert_includes html, 'data-dashboard--detail-panel-component-release-value="null"'
  end

  def test_state_class_attribute_static
    html = DashboardV2::DetailPanelComponent.new.call
    assert_includes html,
      'data-dashboard--detail-panel-component-state-class="fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"'
  end

  def test_class_list_inlines_state_for_ssr
    html = DashboardV2::DetailPanelComponent.new.call
    assert_includes html, "translate-x-full"
  end

  def test_action_bundle_includes_scoped_event_keyboard_and_close
    html = DashboardV2::DetailPanelComponent.new.call
    # Scoped selected event listener
    assert_includes html,
      "dashboard--release-card-component:selected@window->dashboard--detail-panel-component#handleSelected"
    # Keyboard Escape listener
    assert_includes html, "keydown.esc@window->dashboard--detail-panel-component#close"
    # Plain close (for the explicit button)
    assert_includes html, "dashboard--detail-panel-component#close"
  end

  def test_body_target_child_element
    html = DashboardV2::DetailPanelComponent.new.call
    assert_match(/data-dashboard--detail-panel-component-target="body"/, html)
  end
end
