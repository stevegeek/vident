# frozen_string_literal: true

require "test_helper"
require "vident"

class DashboardDetailPanelComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "dashboard/detail_panel_component",
      Dashboard::DetailPanelComponent.stimulus_identifier_path
    assert_equal "dashboard--detail-panel-component",
      Dashboard::DetailPanelComponent.stimulus_identifier
  end

  def test_renders_data_controller_with_dismissable_alias_stacked
    html = Dashboard::DetailPanelComponent.new.call
    # `controller "dashboard/dismissable", as: :dismissable` stacks a
    # second Stimulus controller onto the panel root. Both tokens appear
    # in `data-controller`, preserving declaration order.
    assert_includes html, 'data-controller="dashboard--detail-panel-component dashboard--dismissable"'
  end

  def test_release_value_is_stimulus_null_literal
    # StimulusNull serialises to the literal string "null" so Stimulus's
    # Object parser hands the JS side JSON `null` until the first selection.
    html = Dashboard::DetailPanelComponent.new.call
    assert_includes html, 'data-dashboard--detail-panel-component-release-value="null"'
  end

  def test_state_class_attribute_static
    html = Dashboard::DetailPanelComponent.new.call
    assert_includes html,
      'data-dashboard--detail-panel-component-state-class="fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"'
  end

  def test_class_list_inlines_state_for_ssr
    html = Dashboard::DetailPanelComponent.new.call
    assert_includes html, "translate-x-full"
  end

  def test_action_bundle_includes_scoped_event_keyboard_and_close
    html = Dashboard::DetailPanelComponent.new.call
    # Scoped selected event listener — implied controller
    assert_includes html,
      "dashboard--release-card-component:selected@window->dashboard--detail-panel-component#handleSelected"
    # Kwargs form: `action :close, on: :keydown, keyboard: "esc", window: true`
    assert_includes html, "keydown.esc@window->dashboard--detail-panel-component#close"
    # Plain close (for the explicit button)
    assert_includes html, "dashboard--detail-panel-component#close"
  end

  def test_backspace_action_resolves_dismissable_alias
    # `.on_controller(:dismissable)` routes through the alias declared via
    # `controller "dashboard/dismissable", as: :dismissable` — the
    # emitted handler targets the dismissable token, not the implied panel.
    html = Dashboard::DetailPanelComponent.new.call
    assert_includes html, "keydown.backspace@window->dashboard--dismissable#close"
    refute_includes html, "keydown.backspace@window->dashboard--detail-panel-component#close"
  end

  def test_dblclick_kwargs_form_with_alias_resolves_dismissable
    # Exercises the kwargs shorthand `on: :dblclick, on_controller: :dismissable`
    # — same result as the fluent chain, but via hash options.
    html = Dashboard::DetailPanelComponent.new.call
    assert_includes html, "dblclick->dashboard--dismissable#close"
  end

  def test_body_target_child_element
    html = Dashboard::DetailPanelComponent.new.call
    assert_match(/data-dashboard--detail-panel-component-target="body"/, html)
  end
end
