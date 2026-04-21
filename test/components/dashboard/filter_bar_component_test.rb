# frozen_string_literal: true

require "test_helper"
require "vident"

class DashboardFilterBarComponentTest < Minitest::Test
  def test_stimulus_identifier_matches_v1
    assert_equal "dashboard/filter_bar_component",
      Dashboard::FilterBarComponent.stimulus_identifier_path
    assert_equal "dashboard--filter-bar-component",
      Dashboard::FilterBarComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = Dashboard::FilterBarComponent.new.call
    assert_includes html, 'data-controller="dashboard--filter-bar-component"'
  end

  def test_active_filter_value_from_prop_emitted
    html = Dashboard::FilterBarComponent.new(active_filter: :pending, total: 3).call
    assert_includes html, 'data-dashboard--filter-bar-component-active-filter-value="pending"'
  end

  def test_filter_applied_scoped_action_listens_to_page
    html = Dashboard::FilterBarComponent.new.call
    assert_includes html,
      "dashboard--page-component:filterApplied@window->dashboard--filter-bar-component#handleFilterApplied"
  end

  def test_select_child_element_has_filter_select_action
    html = Dashboard::FilterBarComponent.new.call
    assert_match(/<select\b[^>]*data-action="change->dashboard--filter-bar-component#filterSelect"/, html)
  end

  def test_search_input_has_target_and_action
    html = Dashboard::FilterBarComponent.new.call
    assert_match(/<input\b[^>]*data-action="input->dashboard--filter-bar-component#searchInput"[^>]*data-dashboard--filter-bar-component-target="search"/, html)
  end

  def test_count_span_has_target_and_shows_total
    html = Dashboard::FilterBarComponent.new(total: 7).call
    assert_match(/<span\b[^>]*data-dashboard--filter-bar-component-target="count"[^>]*>7<\/span>/, html)
  end

  def test_select_option_matches_active_filter
    html = Dashboard::FilterBarComponent.new(active_filter: :deployed).call
    # `selected` attribute on the matching option.
    assert_match(/<option\b[^>]*value="deployed"[^>]*selected[^>]*>Deployed<\/option>/, html)
  end
end
