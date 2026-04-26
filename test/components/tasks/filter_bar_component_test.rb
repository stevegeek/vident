# frozen_string_literal: true

require "test_helper"
require "vident"

class TasksFilterBarComponentTest < Minitest::Test
  def test_natural_stimulus_identifier
    assert_equal "tasks/filter_bar_component",
      Tasks::FilterBarComponent.stimulus_identifier_path
    assert_equal "tasks--filter-bar-component",
      Tasks::FilterBarComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = Tasks::FilterBarComponent.new.call
    assert_includes html, 'data-controller="tasks--filter-bar-component"'
  end

  def test_active_filter_value_from_prop_emitted
    html = Tasks::FilterBarComponent.new(active_filter: :todo, total: 3).call
    assert_includes html, 'data-tasks--filter-bar-component-active-filter-value="todo"'
  end

  def test_filter_applied_scoped_action_listens_to_page
    html = Tasks::FilterBarComponent.new.call
    assert_includes html,
      "tasks--page-component:filterApplied@window->tasks--filter-bar-component#handleFilterApplied"
  end

  def test_select_child_element_has_filter_select_action
    html = Tasks::FilterBarComponent.new.call
    assert_match(/<select\b[^>]*data-action="change->tasks--filter-bar-component#filterSelect"/, html)
  end

  def test_search_input_has_target_and_action
    html = Tasks::FilterBarComponent.new.call
    assert_match(/<input\b[^>]*data-action="input->tasks--filter-bar-component#searchInput"[^>]*data-tasks--filter-bar-component-target="search"/, html)
  end

  def test_count_span_has_target_and_shows_total
    html = Tasks::FilterBarComponent.new(total: 7).call
    assert_match(/<span\b[^>]*data-tasks--filter-bar-component-target="count"[^>]*>7<\/span>/, html)
  end

  def test_select_option_matches_active_filter
    html = Tasks::FilterBarComponent.new(active_filter: :wont_do).call
    assert_match(/<option\b[^>]*value="wont_do"[^>]*selected[^>]*>Wont do<\/option>/, html)
  end
end
