# frozen_string_literal: true

module Vident
  module PublicApiSpec
    module DslAdvanced
      def test_action_descriptor_via_parse_descriptor_passthrough
        descriptor = ::Vident::Stimulus::Action.parse_descriptor("click->custom--ctrl#handleIt")
        klass = define_component(name: "ButtonComponent") do
          define_method(:root_element_attributes) { {stimulus_actions: [descriptor]} }
        end
        assert_includes render(klass.new),
          'data-action="click->custom--ctrl#handleIt"'
      end

      def test_action_bare_string_in_dsl_raises_with_descriptor_hint
        e = assert_raises(::Vident::ParseError) do
          klass = define_component(name: "ButtonComponent") do
            stimulus { actions "click->custom--ctrl#handleIt" }
          end
          render(klass.new)
        end
        assert_includes e.message, "parse_descriptor"
      end

      # ---- action: Descriptor typed value object -------------------------

      # ---- action modifiers ---------------------------------------------

      def test_action_hash_with_keyboard_modifier
        klass = define_component(name: "ButtonComponent") do
          stimulus do
            actions({event: :keydown, method: :on_escape, keyboard: "esc", options: [:prevent]})
          end
        end
        assert_includes render(klass.new),
          'data-action="keydown.esc:prevent->button-component#onEscape"'
      end

      def test_action_hash_with_window_true
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions({event: :click, method: :handle, window: true}) }
        end
        assert_includes render(klass.new),
          'data-action="click@window->button-component#handle"'
      end

      def test_action_hash_with_controller_key_routes_cross_controller
        klass = define_component(name: "ButtonComponent") do
          stimulus do
            actions({event: :click, method: :handle, controller: "dialog/open"})
          end
        end
        assert_includes render(klass.new),
          'data-action="click->dialog--open#handle"'
      end

      def test_action_multiple_options_concat_with_colon
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions({event: :click, method: :submit, options: [:once, :prevent, :stop]}) }
        end
        assert_includes render(klass.new),
          'data-action="click:once:prevent:stop->button-component#submit"'
      end

      # ---- cross-controller targets / values / params / classes ---------

      def test_target_cross_controller_via_dsl_array
        klass = define_component(name: "FormComponent") do
          stimulus { targets ["admin/users", :row] }
        end
        assert_includes render(klass.new),
          'data-admin--users-target="row"'
      end

      def test_value_cross_controller_via_array
        klass = define_component(name: "CardComponent") do
          define_method(:root_element_attributes) do
            {stimulus_values: [["other/ctrl", :foo, "bar"]]}
          end
        end
        assert_includes render(klass.new),
          'data-other--ctrl-foo-value="bar"'
      end

      def test_param_cross_controller_via_array
        klass = define_component(name: "ButtonComponent") do
          define_method(:root_element_attributes) do
            {stimulus_params: [["other/ctrl", :scope, "full"]]}
          end
        end
        assert_includes render(klass.new),
          'data-other--ctrl-scope-param="full"'
      end

      # ---- proc action returning nil drops entry ------------------------

      def test_action_proc_returning_nil_drops
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions -> {} }
        end
        refute_match(/data-action=/, render(klass.new))
      end

      # ---- values_from_props multiple names -----------------------------

      def test_values_from_props_multiple_names
        klass = define_component(name: "CardComponent") do
          prop :title, String, default: "Hi"
          prop :count, Integer, default: 3
          stimulus { values_from_props :title, :count }
        end
        html = render(klass.new)
        assert_match(/data-card-component-title-value="Hi"/, html)
        assert_match(/data-card-component-count-value="3"/, html)
      end
    end
  end
end
