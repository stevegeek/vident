# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  # Component-level singular / plural stimulus parsers. Singular returns
  # a Stimulus::<Kind> value object; plural returns a Stimulus::Collection
  # wrapping an Array of items. Collections expose #to_h via the kind's
  # .to_data_hash (splat-into-data-hash pattern).
  class InstanceParsersTest < Minitest::Test
    def make_component(name: "FormComponent")
      klass = Class.new(::Vident::Phlex::HTML)
      klass.define_singleton_method(:name) { name }
      klass
    end

    # ---- singular: returns the right value class ----------------------

    def test_singular_stimulus_target_returns_target_value
      comp = make_component.new
      assert_kind_of ::Vident::Stimulus::Target, comp.stimulus_target(:input)
    end

    def test_singular_stimulus_action_returns_action_value
      comp = make_component(name: "ButtonComponent").new
      assert_kind_of ::Vident::Stimulus::Action, comp.stimulus_action(:click)
    end

    def test_singular_stimulus_controller_returns_controller_value
      comp = make_component(name: "ButtonComponent").new
      assert_kind_of ::Vident::Stimulus::Controller, comp.stimulus_controller("my_ctrl")
    end

    def test_singular_stimulus_value_returns_value
      comp = make_component(name: "CardComponent").new
      assert_kind_of ::Vident::Stimulus::Value, comp.stimulus_value(:title, "hi")
    end

    def test_singular_stimulus_class_returns_classmap
      comp = make_component(name: "PanelComponent").new
      assert_kind_of ::Vident::Stimulus::ClassMap, comp.stimulus_class(:loading, "opacity-50")
    end

    def test_singular_stimulus_outlet_returns_outlet
      comp = make_component(name: "PageComponent").new
      assert_kind_of ::Vident::Stimulus::Outlet, comp.stimulus_outlet(:tab, Vident::Selector(".tab"))
    end

    def test_singular_stimulus_param_returns_param
      comp = make_component(name: "ButtonComponent").new
      assert_kind_of ::Vident::Stimulus::Param, comp.stimulus_param(:kind, "x")
    end

    # ---- pass-through when given a pre-built value --------------------

    def test_singular_pre_built_value_passes_through_unchanged
      comp = make_component.new
      value = comp.stimulus_target(:input)
      assert_same value, comp.stimulus_target(value)
    end

    # ---- to_h on singular value returns symbol key data pair ----------

    def test_singular_target_to_h_uses_symbol_key
      comp = make_component.new
      h = comp.stimulus_target(:input).to_h
      assert_equal({"form-component-target": "input"}, h)
    end

    def test_singular_target_camel_cases_name
      comp = make_component.new
      h = comp.stimulus_target(:submit_button).to_h
      assert_equal "submitButton", h[:"form-component-target"]
    end

    # ---- plural: returns a Collection ---------------------------------

    def test_plural_stimulus_targets_returns_collection
      comp = make_component.new
      assert_kind_of ::Vident::Stimulus::Collection,
        comp.stimulus_targets(:a, :b)
    end

    def test_plural_empty_returns_empty_collection
      comp = make_component.new
      result = comp.stimulus_targets
      assert_kind_of ::Vident::Stimulus::Collection, result
      assert_empty result
    end

    def test_plural_collection_size
      comp = make_component.new
      assert_equal 2, comp.stimulus_targets(:a, :b).size
    end

    # ---- Collection#to_h aggregates per kind --------------------------

    def test_targets_collection_to_h_joins_same_controller_names
      comp = make_component.new
      h = comp.stimulus_targets(:a, :b).to_h
      assert_equal({"form-component-target": "a b"}, h)
    end

    def test_actions_collection_to_h_uses_symbol_action_key
      comp = make_component(name: "ButtonComponent").new
      h = comp.stimulus_actions(:click, :hover).to_h
      assert_equal({action: "button-component#click button-component#hover"}, h)
    end

    def test_controllers_collection_to_h_uses_symbol_controller_key
      comp = make_component(name: "ButtonComponent").new
      h = comp.stimulus_controllers("my_ctrl", "other").to_h
      assert_equal({controller: "my-ctrl other"}, h)
    end

    # ---- pass-through pre-built Collection ----------------------------

    def test_plural_pass_through_pre_built_collection
      comp = make_component.new
      coll = comp.stimulus_targets(:a, :b)
      assert_same coll, comp.stimulus_targets(coll)
    end

    # ---- keyed kinds accept Hash input --------------------------------

    def test_plural_stimulus_values_accepts_hash
      comp = make_component(name: "CardComponent").new
      coll = comp.stimulus_values(count: 1, label: "hi")
      assert_equal 2, coll.size
    end
  end
end
