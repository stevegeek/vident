# frozen_string_literal: true

require "test_helper"
require "vident"

class PhlexGreetersInheritedGreeterComponentTest < Minitest::Test
  def test_inherits_stimulus_identifier_path_override
    assert_equal "phlex_greeters/inherited_greeter_component",
      PhlexGreeters::InheritedGreeterComponent.stimulus_identifier_path
  end

  def test_inherits_parent_stimulus_declarations_and_merges_status_target
    html = PhlexGreeters::InheritedGreeterComponent.new(cta: "X").call

    # The input's target attribute (from the parent template) shows the
    # parent's :name / :another_name targets, now bound to this child's
    # controller name.
    assert_match(/<input\b[^>]*data-phlex-greeters--inherited-greeter-component-target="name anotherName"/, html)
    # The child's stimulus block added the :status target onto the root.
    assert_match(/data-phlex-greeters--inherited-greeter-component-target="status"/, html)
  end

  def test_controllers_prop_appends_additional_controller
    # V2 gotcha-fix #2: stimulus_controllers: at the prop level APPENDS
    # to the implied instead of replacing it. Here the implied
    # (inherited-greeter-component) comes first, then the symbol-form
    # path is added.
    html = PhlexGreeters::InheritedGreeterComponent.new(cta: "X").call
    assert_match(/data-controller="phlex-greeters--inherited-greeter-component phlex-greeters--greeter-vident-component"/, html)
  end
end
