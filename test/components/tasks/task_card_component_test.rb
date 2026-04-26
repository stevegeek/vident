# frozen_string_literal: true

require "test_helper"
require "vident"

class TasksTaskCardComponentTest < Minitest::Test
  def build(overrides = {})
    defaults = {task_id: 42, title: "Write the launch announcement", due: "Today", list: :today, status: :todo}
    Tasks::TaskCardComponent.new(**defaults.merge(overrides))
  end

  def test_natural_stimulus_identifier
    assert_equal "tasks/task_card_component",
      Tasks::TaskCardComponent.stimulus_identifier_path
    assert_equal "tasks--task-card-component",
      Tasks::TaskCardComponent.stimulus_identifier
  end

  def test_props_set_via_instance_vars
    card = build(title: "Alpha", due: "Tue", list: :this_week, status: :done)
    assert_equal 42, card.instance_variable_get(:@task_id)
    assert_equal "Alpha", card.instance_variable_get(:@title)
    assert_equal "Tue", card.instance_variable_get(:@due)
    assert_equal :this_week, card.instance_variable_get(:@list)
    assert_equal :done, card.instance_variable_get(:@status)
  end

  def test_renders_data_controller
    html = build.call
    assert_includes html, 'data-controller="tasks--task-card-component"'
  end

  def test_renders_click_select_action_on_root
    html = build.call
    assert_includes html, 'data-action="click->tasks--task-card-component#select"'
  end

  def test_values_from_props_emits_task_id_title_status
    html = build(task_id: 7, title: "Beta", status: :done).call
    assert_includes html, 'data-tasks--task-card-component-task-id-value="7"'
    assert_includes html, 'data-tasks--task-card-component-title-value="Beta"'
    assert_includes html, 'data-tasks--task-card-component-status-value="done"'
  end

  def test_named_class_attributes_emit_one_per_status
    html = build.call
    assert_includes html,
      'data-tasks--task-card-component-todo-class="border-yellow-400 bg-yellow-50"'
    assert_includes html,
      'data-tasks--task-card-component-done-class="border-green-500 bg-green-50"'
    assert_includes html,
      'data-tasks--task-card-component-wont-do-class="border-gray-400 bg-gray-50"'
  end

  def test_initial_render_inlines_classes_for_current_status
    html = build(status: :done).call
    assert_includes html, "border-green-500"
    assert_includes html, "bg-green-50"

    html = build(status: :wont_do).call
    assert_includes html, "border-gray-400"
    assert_includes html, "bg-gray-50"

    html = build(status: :todo).call
    assert_includes html, "border-yellow-400"
    assert_includes html, "bg-yellow-50"
  end

  # `[^<]*` (not `[^>]*`) is intentional: action values like
  # `click->tasks--task-card-component#apply` contain `>` characters that
  # would prematurely terminate a `[^>]*` match. The `\s` on each side of
  # `disabled` keeps it from matching inside `class="… disabled:opacity-50 …"`.
  def test_done_button_disabled_when_status_already_done
    assert_match(/<button[^<]*\sdisabled\s[^<]*data-tasks--task-card-component-target="doneButton"/,
      build(status: :done).call)
    refute_match(/<button[^<]*\sdisabled\s[^<]*data-tasks--task-card-component-target="doneButton"/,
      build(status: :todo).call)
  end

  def test_dismiss_button_disabled_when_status_already_wont_do
    assert_match(/<button[^<]*\sdisabled\s[^<]*data-tasks--task-card-component-target="dismissButton"/,
      build(status: :wont_do).call)
    refute_match(/<button[^<]*\sdisabled\s[^<]*data-tasks--task-card-component-target="dismissButton"/,
      build(status: :todo).call)
  end

  def test_status_text_target_present
    html = build.call
    assert_match(/data-tasks--task-card-component-target="statusText"/, html)
  end

  def test_title_text_target_present
    html = build.call
    assert_match(/data-tasks--task-card-component-target="titleText"/, html)
  end

  def test_done_button_child_element_has_action_target_and_params
    html = build.call
    assert_match(/<button\b[^>]*data-action="click->tasks--task-card-component#apply"[^>]*data-tasks--task-card-component-target="doneButton"[^>]*data-tasks--task-card-component-kind-param="done"/, html)
  end

  def test_dismiss_button_child_element_has_action_target_and_params
    html = build.call
    assert_match(/<button\b[^>]*data-action="click->tasks--task-card-component#apply"[^>]*data-tasks--task-card-component-target="dismissButton"[^>]*data-tasks--task-card-component-kind-param="dismissed"/, html)
  end

  def test_renders_title_and_due
    html = build(title: "Foo", due: "Mon").call
    assert_match(/<h3[^>]*>Foo<\/h3>/, html)
    assert_includes html, "Due: Mon"
  end

  def test_due_omitted_when_blank
    html = build(due: "").call
    refute_includes html, "Due:"
  end

  def test_strikethrough_when_wont_do
    html = build(status: :wont_do).call
    assert_includes html, "line-through"
  end
end
