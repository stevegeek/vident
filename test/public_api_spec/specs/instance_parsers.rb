# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: instance `stimulus_<kind>(*)` singular + `stimulus_<kind>s(*)`
    # plural parser methods on every component — 14 methods total. These
    # are documented public API (README teaches `data: {**component.stimulus_target(:x)}`
    # in templates). Locks: (a) return types are typed Value / Collection
    # objects, not plain Hashes; (b) #to_h returns the Hash shape suitable
    # for splatting into a `data:` option; (c) pass-through semantics when
    # already a Value/Collection.
    module InstanceParsers
      # ---- singular: returns a typed Value; #to_h = {attr_name => value} --

      def test_stimulus_target_returns_value_object
        klass = define_component(name: "FormComponent")
        assert_kind_of ::Vident::StimulusTarget, klass.new.stimulus_target(:input)
      end

      def test_stimulus_target_to_h_shape
        klass = define_component(name: "FormComponent")
        assert_equal({"form-component-target" => "input"},
          klass.new.stimulus_target(:input).to_h)
      end

      def test_stimulus_target_camel_cases_name
        klass = define_component(name: "FormComponent")
        assert_equal({"form-component-target" => "submitButton"},
          klass.new.stimulus_target(:submit_button).to_h)
      end

      def test_stimulus_target_cross_controller
        klass = define_component(name: "FormComponent")
        assert_equal({"admin--users-target" => "row"},
          klass.new.stimulus_target("admin/users", :row).to_h)
      end

      def test_stimulus_action_returns_value_object
        klass = define_component(name: "ButtonComponent")
        assert_kind_of ::Vident::StimulusAction, klass.new.stimulus_action(:click)
      end

      def test_stimulus_action_to_h_shape
        klass = define_component(name: "ButtonComponent")
        assert_equal({"action" => "button-component#click"},
          klass.new.stimulus_action(:click).to_h)
      end

      def test_stimulus_action_event_method_form
        klass = define_component(name: "ButtonComponent")
        assert_equal({"action" => "click->button-component#handleClick"},
          klass.new.stimulus_action(:click, :handle_click).to_h)
      end

      def test_stimulus_controller_returns_value_object
        klass = define_component(name: "ButtonComponent")
        assert_kind_of ::Vident::StimulusController, klass.new.stimulus_controller("my_ctrl")
      end

      def test_stimulus_controller_to_h_shape
        klass = define_component(name: "ButtonComponent")
        assert_equal({"controller" => "my-ctrl"},
          klass.new.stimulus_controller("my_ctrl").to_h)
      end

      def test_stimulus_value_returns_value_object
        klass = define_component(name: "CardComponent")
        assert_kind_of ::Vident::StimulusValue, klass.new.stimulus_value(:title, "Hi")
      end

      def test_stimulus_value_to_h_shape
        klass = define_component(name: "CardComponent")
        assert_equal({"card-component-title-value" => "Hi"},
          klass.new.stimulus_value(:title, "Hi").to_h)
      end

      def test_stimulus_param_to_h_shape
        klass = define_component(name: "ButtonComponent")
        assert_equal({"button-component-item-id-param" => "42"},
          klass.new.stimulus_param(:item_id, 42).to_h)
      end

      def test_stimulus_class_to_h_shape
        klass = define_component(name: "PanelComponent")
        assert_equal({"panel-component-loading-class" => "opacity-50"},
          klass.new.stimulus_class(:loading, "opacity-50").to_h)
      end

      def test_stimulus_outlet_returns_value_object
        klass = define_component(name: "PageComponent")
        assert_kind_of ::Vident::StimulusOutlet, klass.new.stimulus_outlet(:tab, ".tab")
      end

      # ---- plural: returns a typed Collection; #to_h merges -------------

      def test_stimulus_targets_returns_collection_object
        klass = define_component(name: "FormComponent")
        assert_kind_of ::Vident::StimulusTargetCollection,
          klass.new.stimulus_targets(:a, :b)
      end

      def test_stimulus_targets_collection_to_h_joined_with_space
        # Targets on the same controller concat into one data-*-target attr
        klass = define_component(name: "FormComponent")
        assert_equal({"form-component-target" => "a b"},
          klass.new.stimulus_targets(:a, :b).to_h)
      end

      # SPEC-NOTE (key asymmetry across collections): Action and Controller
      # collections build their #to_h literally (`{action: "..."}` /
      # `{controller: "..."}` with Symbol keys). Target, Value, Param,
      # Class, and Outlet collections iterate items and merge per-item
      # #to_h — their keys come from the individual Value's
      # data_attribute_name (String). Symbol vs String keys splat the same
      # way into `data:` on tags (both are accepted), but literal Hash
      # equality sees them as different. A rename in 2.0 should align on
      # one type.
      def test_stimulus_actions_collection_to_h_uses_symbol_key
        klass = define_component(name: "ButtonComponent")
        assert_equal({action: "button-component#click button-component#hover"},
          klass.new.stimulus_actions(:click, :hover).to_h)
      end

      def test_stimulus_controllers_collection_to_h_uses_symbol_key
        klass = define_component(name: "ButtonComponent")
        assert_equal({controller: "my-ctrl other"},
          klass.new.stimulus_controllers("my_ctrl", "other").to_h)
      end

      def test_stimulus_values_collection_to_h_merges_per_key
        # Each value gets its own data-*-<name>-value; collection merges them
        klass = define_component(name: "CardComponent")
        h = klass.new.stimulus_values(count: 1, label: "x").to_h
        assert_equal "1", h["card-component-count-value"]
        assert_equal "x", h["card-component-label-value"]
      end

      # ---- pass-through semantics ---------------------------------------

      def test_singular_pass_through_pre_built_value
        klass = define_component(name: "FormComponent")
        comp = klass.new
        value = comp.stimulus_target(:input)
        assert_same value, comp.stimulus_target(value)
      end

      def test_plural_pass_through_pre_built_collection
        klass = define_component(name: "FormComponent")
        comp = klass.new
        coll = comp.stimulus_targets(:a, :b)
        assert_same coll, comp.stimulus_targets(coll)
      end

      def test_plural_empty_returns_empty_collection
        klass = define_component(name: "FormComponent")
        result = klass.new.stimulus_targets
        assert_kind_of ::Vident::StimulusTargetCollection, result
      end
    end
  end
end
