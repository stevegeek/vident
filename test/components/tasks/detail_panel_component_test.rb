# frozen_string_literal: true

require "test_helper"
require "vident"

class TasksDetailPanelComponentTest < Minitest::Test
  def test_natural_stimulus_identifier
    assert_equal "tasks/detail_panel_component",
      Tasks::DetailPanelComponent.stimulus_identifier_path
    assert_equal "tasks--detail-panel-component",
      Tasks::DetailPanelComponent.stimulus_identifier
  end

  def test_renders_data_controller_with_dismissable_alias_stacked
    html = Tasks::DetailPanelComponent.new.call
    # `controller "tasks/dismissable", as: :dismissable` stacks a second
    # Stimulus controller onto the panel root.
    assert_includes html, 'data-controller="tasks--detail-panel-component tasks--dismissable"'
  end

  def test_task_value_is_stimulus_null_literal
    # StimulusNull serialises to the literal string "null" so Stimulus's
    # Object parser hands the JS side JSON `null` until the first selection.
    html = Tasks::DetailPanelComponent.new.call
    assert_includes html, 'data-tasks--detail-panel-component-task-value="null"'
  end

  def test_state_class_attribute_static
    html = Tasks::DetailPanelComponent.new.call
    assert_includes html,
      'data-tasks--detail-panel-component-state-class="fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"'
  end

  def test_class_list_inlines_state_for_ssr
    html = Tasks::DetailPanelComponent.new.call
    assert_includes html, "translate-x-full"
  end

  def test_action_bundle_includes_scoped_event_keyboard_and_close
    html = Tasks::DetailPanelComponent.new.call
    assert_includes html,
      "tasks--task-card-component:selected@window->tasks--detail-panel-component#handleSelected"
    assert_includes html, "keydown.esc@window->tasks--detail-panel-component#close"
    assert_includes html, "tasks--detail-panel-component#close"
  end

  def test_backspace_action_resolves_dismissable_alias
    html = Tasks::DetailPanelComponent.new.call
    assert_includes html, "keydown.backspace@window->tasks--dismissable#close"
    refute_includes html, "keydown.backspace@window->tasks--detail-panel-component#close"
  end

  def test_dblclick_kwargs_form_with_alias_resolves_dismissable
    html = Tasks::DetailPanelComponent.new.call
    assert_includes html, "dblclick->tasks--dismissable#close"
  end

  def test_body_target_child_element
    html = Tasks::DetailPanelComponent.new.call
    assert_match(/data-tasks--detail-panel-component-target="body"/, html)
  end
end
