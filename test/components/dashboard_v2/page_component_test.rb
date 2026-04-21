# frozen_string_literal: true

require "test_helper"
require "vident2"

class DashboardV2PageComponentTest < Minitest::Test
  RELEASES = [
    {id: 1, name: "one", version: "1.0.0", environment: :production, status: :deployed},
    {id: 2, name: "two", version: "2.0.0", environment: :staging, status: :pending},
    {id: 3, name: "three", version: "3.0.0", environment: :preview, status: :failed}
  ].freeze

  def build(overrides = {})
    DashboardV2::PageComponent.new(**{releases: RELEASES}.merge(overrides))
  end

  def test_stimulus_identifier_matches_v1
    assert_equal "dashboard/page_component",
      DashboardV2::PageComponent.stimulus_identifier_path
    assert_equal "dashboard--page-component",
      DashboardV2::PageComponent.stimulus_identifier
  end

  def test_renders_data_controller
    html = build.call
    assert_includes html, 'data-controller="dashboard--page-component"'
  end

  def test_scoped_filter_changed_action_bound_to_page
    html = build.call
    assert_includes html,
      "dashboard--filter-bar-component:filterChanged@window->dashboard--page-component#handleFilterChanged"
  end

  def test_active_filter_and_count_values_on_root
    html = build(active_filter: :pending).call
    assert_includes html, 'data-dashboard--page-component-active-filter-value="pending"'
    assert_includes html, 'data-dashboard--page-component-count-value="3"'
  end

  def test_outlet_attribute_registered_from_child_outlet_host
    # Child card components self-register on the host via `stimulus_outlet_host:`
    # during their `after_initialize`. The page's Draft is still open during
    # the block capture, so the outlet makes it into the sealed Plan.
    html = build.call
    # Outlet attr format: `data-<host-ident>-<child-ident>-outlet="<selector>"`.
    # CSS-selector form is the auto-generated selector; one attribute (not
    # per-child), because outlet keys collapse last-write-wins.
    assert_match(/data-dashboard--page-component-dashboard--release-card-component-outlet="[^"]+dashboard--release-card-component[^"]*"/, html)
  end

  def test_renders_filter_bar_detail_panel_and_toast_children
    html = build.call
    assert_includes html, 'data-controller="dashboard--filter-bar-component"'
    assert_includes html, 'data-controller="dashboard--detail-panel-component"'
    assert_includes html, 'data-controller="dashboard--toast-component"'
  end

  def test_renders_one_release_card_per_release
    html = build.call
    card_matches = html.scan('data-controller="dashboard--release-card-component"').size
    assert_equal RELEASES.size, card_matches
  end

  def test_renders_with_empty_releases
    html = DashboardV2::PageComponent.new.call
    assert_includes html, 'data-controller="dashboard--page-component"'
    assert_includes html, 'data-dashboard--page-component-count-value="0"'
    refute_includes html, 'data-controller="dashboard--release-card-component"'
  end
end
