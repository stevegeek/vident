# frozen_string_literal: true

require "test_helper"
require "vident"

class TasksToastComponentTest < Minitest::Test
  def test_natural_stimulus_identifier
    assert_equal "tasks/toast_component",
      Tasks::ToastComponent.stimulus_identifier_path
    assert_equal "tasks--toast-component",
      Tasks::ToastComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = Tasks::ToastComponent.new.call
    assert_includes html, 'data-controller="tasks--toast-component"'
  end

  def test_auto_dismiss_ms_value_from_prop
    html = Tasks::ToastComponent.new(auto_dismiss_ms: 1500).call
    assert_includes html, 'data-tasks--toast-component-auto-dismiss-ms-value="1500"'
  end

  def test_message_value_is_stimulus_null_literal
    html = Tasks::ToastComponent.new.call
    assert_includes html, 'data-tasks--toast-component-message-value="null"'
  end

  def test_done_and_dismissed_scoped_listeners
    html = Tasks::ToastComponent.new.call
    assert_includes html,
      "tasks--task-card-component:done@window->tasks--toast-component#handleDone"
    assert_includes html,
      "tasks--task-card-component:dismissed@window->tasks--toast-component#handleDismissed"
  end

  def test_dismiss_action_on_root
    html = Tasks::ToastComponent.new.call
    assert_includes html, "tasks--toast-component#dismiss"
  end

  def test_container_and_message_targets_present
    html = Tasks::ToastComponent.new.call
    assert_includes html, 'data-tasks--toast-component-target="container"'
    assert_includes html, 'data-tasks--toast-component-target="message"'
  end
end
