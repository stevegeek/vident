# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  class ClassLevelStimulusBuildersTest < Minitest::Test
    def make_component(name: "FormComponent")
      klass = Class.new(::Vident::Phlex::HTML)
      klass.define_singleton_method(:name) { name }
      klass
    end

    # ---- stimulus_controller -------------------------------------------

    def test_stimulus_controller_returns_controller_value_class
      klass = make_component(name: "FormComponent")
      assert_kind_of ::Vident::Stimulus::Controller, klass.stimulus_controller
    end

    def test_stimulus_controller_reflects_implied_identifier
      klass = make_component(name: "FormComponent")
      assert_equal "form-component", klass.stimulus_controller.name
    end

    # ---- stimulus_target -----------------------------------------------

    def test_stimulus_target_returns_target_value_class
      klass = make_component(name: "FormComponent")
      assert_kind_of ::Vident::Stimulus::Target, klass.stimulus_target(:input)
    end

    def test_stimulus_target_uses_class_implied_controller
      klass = make_component(name: "CardComponent")
      t = klass.stimulus_target(:row)
      assert_equal "card-component", t.controller.name
      assert_equal "row", t.name
    end

    def test_stimulus_target_camelizes_snake_case_name
      klass = make_component(name: "FormComponent")
      t = klass.stimulus_target(:submit_button)
      assert_equal "submitButton", t.name
    end

    def test_stimulus_target_cross_controller_form_raises
      klass = make_component(name: "FormComponent")
      assert_raises(::Vident::ParseError) do
        klass.stimulus_target("other/ctrl", :x)
      end
    end

    def test_stimulus_target_cross_controller_error_message_is_helpful
      klass = make_component(name: "FormComponent")
      err = assert_raises(::Vident::ParseError) { klass.stimulus_target("other/ctrl", :x) }
      assert_match(/cross-controller/, err.message)
    end

    # ---- stimulus_action -----------------------------------------------

    def test_stimulus_action_returns_action_value_class
      klass = make_component(name: "ButtonComponent")
      assert_kind_of ::Vident::Stimulus::Action, klass.stimulus_action(:click)
    end

    def test_stimulus_action_single_symbol_is_method_on_implied_controller
      klass = make_component(name: "ButtonComponent")
      a = klass.stimulus_action(:click)
      assert_equal "button-component", a.controller.name
      assert_equal "click", a.method_name
      assert_nil a.event
    end

    def test_stimulus_action_symbol_symbol_is_event_method
      klass = make_component(name: "ButtonComponent")
      a = klass.stimulus_action(:submit, :handle_submit)
      assert_equal "submit", a.event
      assert_equal "handleSubmit", a.method_name
    end

    def test_stimulus_action_cross_controller_string_symbol_raises
      klass = make_component(name: "ButtonComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_action("other/ctrl", :handle) }
    end

    def test_stimulus_action_cross_controller_event_string_symbol_raises
      klass = make_component(name: "ButtonComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_action(:click, "other/ctrl", :handle) }
    end

    # ---- stimulus_value ------------------------------------------------

    def test_stimulus_value_returns_value_class
      klass = make_component(name: "CardComponent")
      assert_kind_of ::Vident::Stimulus::Value, klass.stimulus_value(:title, "hello")
    end

    def test_stimulus_value_uses_class_implied_controller
      klass = make_component(name: "CardComponent")
      v = klass.stimulus_value(:count, 42)
      assert_equal "card-component", v.controller.name
      assert_equal "count", v.name
      assert_equal "42", v.serialized
    end

    def test_stimulus_value_cross_controller_form_raises
      klass = make_component(name: "CardComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_value("other/ctrl", :count, 1) }
    end

    # ---- stimulus_param ------------------------------------------------

    def test_stimulus_param_returns_param_class
      klass = make_component(name: "ButtonComponent")
      assert_kind_of ::Vident::Stimulus::Param, klass.stimulus_param(:kind, "primary")
    end

    def test_stimulus_param_uses_class_implied_controller
      klass = make_component(name: "ButtonComponent")
      p = klass.stimulus_param(:item_id, 7)
      assert_equal "button-component", p.controller.name
      assert_equal "item-id", p.name
      assert_equal "7", p.serialized
    end

    def test_stimulus_param_cross_controller_form_raises
      klass = make_component(name: "ButtonComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_param("other/ctrl", :id, 1) }
    end

    # ---- stimulus_class ------------------------------------------------

    def test_stimulus_class_returns_class_map_class
      klass = make_component(name: "PanelComponent")
      assert_kind_of ::Vident::Stimulus::ClassMap, klass.stimulus_class(:loading, "opacity-50")
    end

    def test_stimulus_class_uses_class_implied_controller
      klass = make_component(name: "PanelComponent")
      cm = klass.stimulus_class(:active, "bg-blue")
      assert_equal "panel-component", cm.controller.name
      assert_equal "active", cm.name
      assert_equal "bg-blue", cm.css
    end

    def test_stimulus_class_cross_controller_form_raises
      klass = make_component(name: "PanelComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_class("other/ctrl", :loading, "x") }
    end

    # ---- stimulus_outlet -----------------------------------------------

    def test_stimulus_outlet_with_selector_returns_outlet_class
      klass = make_component(name: "PageComponent")
      assert_kind_of ::Vident::Stimulus::Outlet, klass.stimulus_outlet(:modal, Vident::Selector(".js-modal"))
    end

    def test_stimulus_outlet_with_selector_uses_class_implied_controller
      klass = make_component(name: "PageComponent")
      o = klass.stimulus_outlet(:tab, Vident::Selector(".tab-panel"))
      assert_equal "page-component", o.controller.name
      assert_equal "tab", o.name
      assert_equal ".tab-panel", o.selector
    end

    def test_stimulus_outlet_string_name_with_selector_accepted
      klass = make_component(name: "PageComponent")
      o = klass.stimulus_outlet("modal", Vident::Selector(".js-modal"))
      assert_equal "modal", o.name
      assert_equal ".js-modal", o.selector
    end

    def test_stimulus_outlet_without_selector_raises_parse_error
      klass = make_component(name: "PageComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_outlet(:modal) }
    end

    def test_stimulus_outlet_raw_string_selector_raises
      klass = make_component(name: "PageComponent")
      assert_raises(::Vident::ParseError) { klass.stimulus_outlet(:modal, ".js-modal") }
    end

    def test_stimulus_outlet_without_selector_error_message_is_helpful
      klass = make_component(name: "PageComponent")
      err = assert_raises(::Vident::ParseError) { klass.stimulus_outlet(:modal) }
      assert_match(/Selector/, err.message)
    end

    # ---- Inheritance: subclass uses its own implied controller ----------

    def test_subclass_target_uses_child_implied_controller
      parent = make_component(name: "ParentComponent")
      child = Class.new(parent)
      child.define_singleton_method(:name) { "ChildComponent" }

      t = child.stimulus_target(:row)
      assert_equal "child-component", t.controller.name
    end

    def test_parent_implied_controller_not_shared_with_child
      parent = make_component(name: "ParentComponent")
      child = Class.new(parent)
      child.define_singleton_method(:name) { "ChildComponent" }

      parent_ctrl = parent.stimulus_controller
      child_ctrl = child.stimulus_controller
      refute_equal parent_ctrl.name, child_ctrl.name
    end

    def test_memoization_is_per_class_not_shared
      parent = make_component(name: "Alpha::ParentComponent")
      child = Class.new(parent)
      child.define_singleton_method(:name) { "Alpha::ChildComponent" }

      assert_equal "alpha--parent-component", parent.stimulus_controller.name
      assert_equal "alpha--child-component", child.stimulus_controller.name
    end

    # ---- stimulus_identifier_path override respected -------------------

    def test_overridden_stimulus_identifier_path_is_used_at_class_level
      klass = make_component(name: "Wrapped::SpecialComponent")
      klass.define_singleton_method(:stimulus_identifier_path) { "custom/path" }

      t = klass.stimulus_target(:item)
      assert_equal "custom--path", t.controller.name
    end

    # ---- Sanity: class-level matches instance-level output -------------

    def test_class_level_target_to_h_matches_instance_level
      klass = make_component(name: "FormComponent")
      instance = klass.new

      class_h = klass.stimulus_target(:input).to_h
      instance_h = instance.stimulus_target(:input).to_h
      assert_equal instance_h, class_h
    end

    def test_class_level_action_to_h_matches_instance_level
      klass = make_component(name: "ButtonComponent")
      instance = klass.new

      assert_equal instance.stimulus_action(:click).to_h, klass.stimulus_action(:click).to_h
    end

    def test_class_level_value_to_h_matches_instance_level
      klass = make_component(name: "CardComponent")
      instance = klass.new

      assert_equal instance.stimulus_value(:count, 5).to_h, klass.stimulus_value(:count, 5).to_h
    end

    def test_class_level_outlet_to_h_matches_instance_level_with_explicit_selector
      klass = make_component(name: "PageComponent")
      instance = klass.new
      sel = Vident::Selector(".tab-panel")

      assert_equal(
        instance.stimulus_outlet(:tab, sel).to_h,
        klass.stimulus_outlet(:tab, sel).to_h
      )
    end
  end
end
