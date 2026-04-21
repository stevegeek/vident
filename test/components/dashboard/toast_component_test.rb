# frozen_string_literal: true

require "test_helper"
require "vident"

class DashboardToastComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "dashboard/toast_component",
      Dashboard::ToastComponent.stimulus_identifier_path
    assert_equal "dashboard--toast-component",
      Dashboard::ToastComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = Dashboard::ToastComponent.new.call
    assert_includes html, 'data-controller="dashboard--toast-component"'
  end

  def test_auto_dismiss_ms_value_from_prop
    html = Dashboard::ToastComponent.new(auto_dismiss_ms: 1500).call
    assert_includes html, 'data-dashboard--toast-component-auto-dismiss-ms-value="1500"'
  end

  def test_message_value_is_stimulus_null_literal
    html = Dashboard::ToastComponent.new.call
    assert_includes html, 'data-dashboard--toast-component-message-value="null"'
  end

  def test_promoted_and_cancelled_scoped_listeners
    html = Dashboard::ToastComponent.new.call
    assert_includes html,
      "dashboard--release-card-component:promoted@window->dashboard--toast-component#handlePromoted"
    assert_includes html,
      "dashboard--release-card-component:cancelled@window->dashboard--toast-component#handleCancelled"
  end

  def test_dismiss_action_on_root
    html = Dashboard::ToastComponent.new.call
    assert_includes html, "dashboard--toast-component#dismiss"
  end

  def test_container_and_message_targets_present
    html = Dashboard::ToastComponent.new.call
    assert_includes html, 'data-dashboard--toast-component-target="container"'
    assert_includes html, 'data-dashboard--toast-component-target="message"'
  end
end
