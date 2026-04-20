# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # VC-only. Covers the 14 `as_stimulus_*` helpers (7 kinds × singular +
    # plural) on Vident::ViewComponent::Base — used in ERB templates as
    # `<span <%= component.as_stimulus_target(:x) %>>`. Each returns an
    # HTML-safe `data-...="..."` string (ActiveSupport::SafeBuffer).
    #
    # Included only in view_component_v1_test.rb (not Phlex, which uses
    # child_element / direct tag DSL instead).
    module VcAsStimulus
      def build_component(name: "GreeterComponent", &block)
        define_component(name: name, &block).new
      end

      # ---- target --------------------------------------------------------

      def test_as_stimulus_target_basic
        comp = build_component
        assert_equal %q{data-greeter-component-target="button"},
          comp.as_stimulus_target(:button).to_s
        assert_kind_of ActiveSupport::SafeBuffer, comp.as_stimulus_target(:button)
      end

      def test_as_stimulus_target_snake_case_becomes_camel_case
        comp = build_component
        assert_equal %q{data-greeter-component-target="errorMessage"},
          comp.as_stimulus_target(:error_message).to_s
      end

      def test_as_stimulus_target_cross_controller
        comp = build_component
        assert_equal %q{data-custom--ctrl-target="input"},
          comp.as_stimulus_target("custom/ctrl", :input).to_s
      end

      def test_as_stimulus_targets_plural_multiple
        comp = build_component
        assert_equal %q{data-greeter-component-target="button input"},
          comp.as_stimulus_targets(:button, :input).to_s
      end

      def test_as_stimulus_targets_empty_returns_empty_safe_buffer
        comp = build_component
        assert_equal "", comp.as_stimulus_targets.to_s
      end

      # ---- action --------------------------------------------------------

      def test_as_stimulus_action_basic
        comp = build_component
        assert_equal %q{data-action="greeter-component#click"},
          comp.as_stimulus_action(:click).to_s
      end

      def test_as_stimulus_action_with_event
        comp = build_component
        assert_equal %q{data-action="submit->greeter-component#save"},
          comp.as_stimulus_action(:submit, :save).to_s
      end

      def test_as_stimulus_actions_multiple
        comp = build_component
        assert_equal %q{data-action="greeter-component#click submit->greeter-component#save"},
          comp.as_stimulus_actions(:click, [:submit, :save]).to_s
      end

      # ---- controller ----------------------------------------------------

      def test_as_stimulus_controller_basic
        comp = build_component
        assert_equal %q{data-controller="my-controller"},
          comp.as_stimulus_controller("my_controller").to_s
      end

      def test_as_stimulus_controller_nested_path
        comp = build_component
        assert_equal %q{data-controller="forms--validation"},
          comp.as_stimulus_controller("forms/validation").to_s
      end

      def test_as_stimulus_controllers_multiple
        comp = build_component
        assert_equal %q{data-controller="a b"},
          comp.as_stimulus_controllers("a", "b").to_s
      end

      # ---- value ---------------------------------------------------------

      def test_as_stimulus_value_basic
        comp = build_component
        assert_equal %q{data-greeter-component-url-value="https://example.com"},
          comp.as_stimulus_value(:url, "https://example.com").to_s
      end

      def test_as_stimulus_value_cross_controller
        comp = build_component
        assert_equal %q{data-api-controller-endpoint-value="/api/users"},
          comp.as_stimulus_value("api_controller", :endpoint, "/api/users").to_s
      end

      def test_as_stimulus_values_multiple
        comp = build_component
        result = comp.as_stimulus_values(foo: "bar", count: 1).to_s
        assert_match(/data-greeter-component-foo-value="bar"/, result)
        assert_match(/data-greeter-component-count-value="1"/, result)
      end

      # ---- param ---------------------------------------------------------

      def test_as_stimulus_param_basic
        comp = build_component
        assert_equal %q{data-greeter-component-kind-param="promote"},
          comp.as_stimulus_param(:kind, "promote").to_s
      end

      def test_as_stimulus_params_multiple
        comp = build_component
        result = comp.as_stimulus_params(a: 1, b: 2).to_s
        assert_match(/data-greeter-component-a-param="1"/, result)
        assert_match(/data-greeter-component-b-param="2"/, result)
      end

      # ---- class ---------------------------------------------------------

      def test_as_stimulus_class_basic
        comp = build_component
        assert_equal %q{data-greeter-component-loading-class="opacity-50"},
          comp.as_stimulus_class(:loading, "opacity-50").to_s
      end

      def test_as_stimulus_classes_multiple
        comp = build_component
        result = comp.as_stimulus_classes(a: "x", b: "y").to_s
        assert_match(/data-greeter-component-a-class="x"/, result)
        assert_match(/data-greeter-component-b-class="y"/, result)
      end

      # ---- outlet --------------------------------------------------------

      def test_as_stimulus_outlet_basic
        comp = build_component
        assert_equal %q{data-greeter-component-modal-outlet=".modal"},
          comp.as_stimulus_outlet(:modal, ".modal").to_s
      end
    end
  end
end
