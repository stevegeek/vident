# frozen_string_literal: true

require "test_helper"
require "vident"

class TasksPageComponentTest < Minitest::Test
  TASKS = [
    {id: 1, title: "one", due: "Mon", list: :today, status: :todo},
    {id: 2, title: "two", due: "Tue", list: :this_week, status: :done},
    {id: 3, title: "three", due: "Wed", list: :backlog, status: :wont_do}
  ].freeze

  def build(overrides = {})
    Tasks::PageComponent.new(tasks: TASKS, **overrides)
  end

  def test_natural_stimulus_identifier
    assert_equal "tasks/page_component",
      Tasks::PageComponent.stimulus_identifier_path
    assert_equal "tasks--page-component",
      Tasks::PageComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = build.call
    assert_includes html, 'data-controller="tasks--page-component"'
  end

  def test_scoped_filter_changed_action_bound_to_page
    html = build.call
    assert_includes html,
      "tasks--filter-bar-component:filterChanged@window->tasks--page-component#handleFilterChanged"
  end

  def test_active_filter_and_count_values_on_root
    html = build(active_filter: :todo).call
    assert_includes html, 'data-tasks--page-component-active-filter-value="todo"'
    assert_includes html, 'data-tasks--page-component-count-value="3"'
  end

  def test_outlet_attribute_registered_from_child_outlet_host
    html = build.call
    assert_match(/data-tasks--page-component-tasks--task-card-component-outlet="[^"]+tasks--task-card-component[^"]*"/, html)
  end

  def test_renders_filter_bar_detail_panel_and_toast_children
    html = build.call
    assert_includes html, 'data-controller="tasks--filter-bar-component"'
    assert_includes html, 'data-controller="tasks--detail-panel-component tasks--dismissable"'
    assert_includes html, 'data-controller="tasks--toast-component"'
  end

  def test_renders_one_task_card_per_task
    html = build.call
    card_matches = html.scan('data-controller="tasks--task-card-component"').size
    assert_equal TASKS.size, card_matches
  end

  def test_renders_with_empty_tasks
    html = Tasks::PageComponent.new.call
    assert_includes html, 'data-controller="tasks--page-component"'
    assert_includes html, 'data-tasks--page-component-count-value="0"'
    refute_includes html, 'data-controller="tasks--task-card-component"'
  end
end
