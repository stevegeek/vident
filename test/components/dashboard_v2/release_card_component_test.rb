# frozen_string_literal: true

require "test_helper"
require "vident2"

class DashboardV2ReleaseCardComponentTest < Minitest::Test
  def build(overrides = {})
    defaults = {release_id: 42, name: "Widget", version: "1.2.3", environment: :production, status: :deployed}
    DashboardV2::ReleaseCardComponent.new(**defaults.merge(overrides))
  end

  def test_stimulus_identifier_matches_v1
    assert_equal "dashboard/release_card_component",
      DashboardV2::ReleaseCardComponent.stimulus_identifier_path
    assert_equal "dashboard--release-card-component",
      DashboardV2::ReleaseCardComponent.stimulus_identifier
  end

  def test_props_set_via_instance_vars
    card = build(name: "Alpha", version: "9.9", environment: :staging, status: :pending)
    assert_equal 42, card.instance_variable_get(:@release_id)
    assert_equal "Alpha", card.instance_variable_get(:@name)
    assert_equal "9.9", card.instance_variable_get(:@version)
    assert_equal :staging, card.instance_variable_get(:@environment)
    assert_equal :pending, card.instance_variable_get(:@status)
  end

  def test_renders_data_controller
    html = build.call
    assert_includes html, 'data-controller="dashboard--release-card-component"'
  end

  def test_renders_click_select_action_on_root
    html = build.call
    assert_includes html, 'data-action="click->dashboard--release-card-component#select"'
  end

  def test_values_from_props_emits_release_id_name_status
    html = build(release_id: 7, name: "Beta", status: :deployed).call
    assert_includes html, 'data-dashboard--release-card-component-release-id-value="7"'
    assert_includes html, 'data-dashboard--release-card-component-name-value="Beta"'
    assert_includes html, 'data-dashboard--release-card-component-status-value="deployed"'
  end

  def test_status_class_map_attribute_reflects_proc_result
    html = build(status: :deployed).call
    assert_includes html,
      'data-dashboard--release-card-component-status-class="border-green-500 bg-green-50"'

    html = build(status: :failed).call
    assert_includes html,
      'data-dashboard--release-card-component-status-class="border-red-500 bg-red-50"'

    html = build(status: :pending).call
    assert_includes html,
      'data-dashboard--release-card-component-status-class="border-yellow-400 bg-yellow-50"'
  end

  def test_class_list_for_stimulus_classes_inlines_resolved_status
    html = build(status: :deployed).call
    assert_includes html, "border-green-500"
    assert_includes html, "bg-green-50"
  end

  def test_promote_button_child_element_has_action_target_and_params
    html = build.call
    assert_match(/<button\b[^>]*data-action="click->dashboard--release-card-component#apply"[^>]*data-dashboard--release-card-component-target="promoteButton"[^>]*data-dashboard--release-card-component-kind-param="promote"/, html)
  end

  def test_cancel_button_child_element_has_action_target_and_params
    html = build.call
    assert_match(/<button\b[^>]*data-action="click->dashboard--release-card-component#apply"[^>]*data-dashboard--release-card-component-target="cancelButton"[^>]*data-dashboard--release-card-component-kind-param="cancel"/, html)
  end

  def test_renders_name_and_version
    html = build(name: "Foo", version: "7.8").call
    assert_match(/<h3[^>]*>Foo<\/h3>/, html)
    assert_match(/<p[^>]*>v7\.8<\/p>/, html)
  end
end
