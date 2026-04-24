# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  class RootElementHelpersTest < Minitest::Test
    def make_component(name: "TestComponent", &block)
      klass = Class.new(::Vident::Phlex::HTML)
      klass.define_singleton_method(:name) { name }
      klass.define_method(:view_template) { root_element }
      klass.class_eval(&block) if block
      klass
    end

    # ---- root_element_class_list -------------------------------------------

    def test_class_list_returns_component_name_by_default
      klass = make_component(name: "ButtonComponent")
      assert_equal "button-component", klass.new.root_element_class_list
    end

    def test_class_list_includes_classes_prop
      klass = make_component(name: "ButtonComponent")
      assert_equal "button-component extra",
        klass.new(classes: "extra").root_element_class_list
    end

    def test_class_list_includes_html_options_class
      klass = make_component(name: "ButtonComponent")
      assert_equal "button-component themed",
        klass.new(html_options: {class: "themed"}).root_element_class_list
    end

    def test_class_list_includes_root_element_classes_override
      klass = make_component(name: "ButtonComponent") do
        define_method(:root_element_classes) { "base-class" }
      end
      assert_equal "button-component base-class", klass.new.root_element_class_list
    end

    def test_extra_classes_appended_after_classes_prop
      klass = make_component(name: "ButtonComponent")
      result = klass.new(classes: "primary").root_element_class_list("extra")
      assert_equal "button-component primary extra", result
    end

    def test_extra_classes_array_appended
      klass = make_component(name: "ButtonComponent")
      result = klass.new.root_element_class_list(["one", "two"])
      assert_equal "button-component one two", result
    end

    def test_extra_classes_nil_returns_base_list
      klass = make_component(name: "ButtonComponent")
      assert_equal "button-component", klass.new.root_element_class_list(nil)
    end

    def test_extra_classes_with_tailwind_conflict_merges
      skip "Tailwind merger not loaded" unless defined?(::TailwindMerge::Merger)
      klass = make_component(name: "ButtonComponent")
      # p-2 from html_options + p-4 from extra_classes: merger keeps last
      result = klass.new(html_options: {class: "p-2"}).root_element_class_list("p-4")
      assert_match(/p-4/, result)
      refute_match(/p-2/, result)
    end

    def test_class_list_no_stimulus_controller_still_emits_component_name
      klass = make_component(name: "IconComponent") do
        no_stimulus_controller
      end
      result = klass.new.root_element_class_list
      assert_match(/icon-component/, result)
    end

    def test_class_list_no_stimulus_controller_includes_classes_prop
      klass = make_component(name: "IconComponent") do
        no_stimulus_controller
      end
      result = klass.new(classes: "my-icon").root_element_class_list
      assert_equal "icon-component my-icon", result
    end

    def test_class_list_returns_string_not_nil
      klass = make_component(name: "ButtonComponent")
      assert_kind_of String, klass.new.root_element_class_list
    end

    def test_explicit_id_prop_does_not_affect_class_list
      klass = make_component(name: "ButtonComponent")
      assert_equal "button-component",
        klass.new(id: "my-btn").root_element_class_list
    end

    # ---- root_element_data_attributes --------------------------------------

    def test_data_attributes_returns_hash
      klass = make_component(name: "ButtonComponent")
      assert_kind_of Hash, klass.new.root_element_data_attributes
    end

    def test_data_attributes_keys_are_symbols
      klass = make_component(name: "ButtonComponent")
      klass.new.root_element_data_attributes.each_key do |k|
        assert_kind_of Symbol, k
      end
    end

    def test_data_attributes_includes_controller
      klass = make_component(name: "ButtonComponent")
      attrs = klass.new.root_element_data_attributes
      assert_equal "button-component", attrs[:controller]
    end

    def test_data_attributes_no_stimulus_controller_absent
      klass = make_component(name: "IconComponent") do
        no_stimulus_controller
      end
      attrs = klass.new.root_element_data_attributes
      refute attrs.key?(:controller)
    end

    def test_data_attributes_includes_stimulus_action
      klass = make_component(name: "ButtonComponent") do
        stimulus { actions :click }
      end
      attrs = klass.new.root_element_data_attributes
      assert_equal "button-component#click", attrs[:action]
    end

    def test_data_attributes_includes_stimulus_value
      klass = make_component(name: "CardComponent") do
        stimulus { values label: "hello" }
      end
      attrs = klass.new.root_element_data_attributes
      assert_equal "hello", attrs[:"card-component-label-value"]
    end

    def test_data_attributes_includes_stimulus_param
      klass = make_component(name: "ButtonComponent") do
        stimulus { params kind: "promote" }
      end
      attrs = klass.new.root_element_data_attributes
      assert_equal "promote", attrs[:"button-component-kind-param"]
    end

    def test_data_attributes_includes_stimulus_class
      klass = make_component(name: "PanelComponent") do
        stimulus { classes loading: "opacity-50" }
      end
      attrs = klass.new.root_element_data_attributes
      assert_equal "opacity-50", attrs[:"panel-component-loading-class"]
    end

    def test_data_attributes_includes_stimulus_target
      klass = make_component(name: "FormComponent") do
        stimulus { targets :input }
      end
      attrs = klass.new.root_element_data_attributes
      assert_equal "input", attrs[:"form-component-target"]
    end

    def test_data_attributes_merges_html_options_data
      klass = make_component(name: "ButtonComponent")
      attrs = klass.new(html_options: {data: {custom: "yes"}}).root_element_data_attributes
      assert_equal "yes", attrs[:custom]
      assert_equal "button-component", attrs[:controller]
    end

    def test_data_attributes_html_options_data_wins_over_plan
      klass = make_component(name: "ButtonComponent")
      attrs = klass.new(html_options: {data: {controller: "override"}}).root_element_data_attributes
      assert_equal "override", attrs[:controller]
    end

    def test_data_attributes_all_dsl_primitives_one_each
      klass = make_component(name: "FullComponent") do
        prop :item_id, Integer, default: 1
        stimulus do
          actions :click
          targets :output
          values count: 5
          params kind: "go"
          classes loading: "spin"
        end
      end
      attrs = klass.new.root_element_data_attributes
      assert_equal "full-component", attrs[:controller]
      assert_equal "full-component#click", attrs[:action]
      assert_equal "output", attrs[:"full-component-target"]
      assert_equal "5", attrs[:"full-component-count-value"]
      assert_equal "go", attrs[:"full-component-kind-param"]
      assert_equal "spin", attrs[:"full-component-loading-class"]
    end

    def test_seal_is_idempotent_across_multiple_calls
      klass = make_component(name: "ButtonComponent")
      comp = klass.new
      first = comp.root_element_data_attributes
      second = comp.root_element_data_attributes
      assert_equal first, second
    end

    def test_can_call_class_list_and_data_attributes_independently
      klass = make_component(name: "ButtonComponent") do
        stimulus { actions :click }
      end
      comp = klass.new(classes: "primary")
      cl = comp.root_element_class_list
      da = comp.root_element_data_attributes
      assert_equal "button-component primary", cl
      assert_equal "button-component#click", da[:action]
    end
  end
end
