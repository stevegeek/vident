# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: the `stimulus do ... end` DSL primitives — actions, targets,
    # values, values_from_props, params, classes, outlets. One spec per
    # input shape documented in skills/vident/SKILL.md §1.
    #
    # Adapter-agnostic: included by both the Phlex and the ViewComponent
    # runners. The helpers (#define_component, #render) come from the
    # adapter module mixed in alongside.
    module CoreDSL
      # ---- actions --------------------------------------------------------

      def test_actions_symbol_emits_implied_controller_reference
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions :click }
        end
        assert_includes render(klass.new), 'data-action="button-component#click"'
      end

      def test_actions_symbol_is_camel_cased_in_method_name
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions :handle_click }
        end
        assert_includes render(klass.new), 'data-action="button-component#handleClick"'
      end

      def test_actions_array_pair_adds_event_prefix
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions [:click, :handle_click] }
        end
        assert_includes render(klass.new), 'data-action="click->button-component#handleClick"'
      end

      def test_actions_array_triple_routes_to_cross_controller
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions [:click, "dialog/open", :show] }
        end
        assert_includes render(klass.new), 'data-action="click->dialog--open#show"'
      end

      def test_actions_multiple_join_with_space
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions :click, :hover }
        end
        assert_includes render(klass.new), 'data-action="button-component#click button-component#hover"'
      end

      def test_actions_hash_descriptor_with_modifier_options
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions({event: :click, method: :submit, options: [:once, :prevent]}) }
        end
        assert_includes render(klass.new), 'data-action="click:once:prevent->button-component#submit"'
      end

      # ---- targets --------------------------------------------------------

      def test_targets_symbol_emits_implied_target_attribute
        klass = define_component(name: "FormComponent") do
          stimulus { targets :input }
        end
        assert_includes render(klass.new), 'data-form-component-target="input"'
      end

      def test_targets_multiple_same_controller_concat_in_one_attribute
        klass = define_component(name: "FormComponent") do
          stimulus { targets :input, :output }
        end
        assert_includes render(klass.new), 'data-form-component-target="input output"'
      end

      def test_targets_symbol_is_camel_cased
        klass = define_component(name: "FormComponent") do
          stimulus { targets :submit_button }
        end
        assert_includes render(klass.new), 'data-form-component-target="submitButton"'
      end

      # ---- values ---------------------------------------------------------

      def test_values_static_string
        klass = define_component(name: "CardComponent") do
          stimulus { values label: "hello" }
        end
        assert_includes render(klass.new), 'data-card-component-label-value="hello"'
      end

      def test_values_static_integer_stringifies
        klass = define_component(name: "CardComponent") do
          stimulus { values count: 42 }
        end
        assert_includes render(klass.new), 'data-card-component-count-value="42"'
      end

      def test_values_static_boolean_stringifies
        klass = define_component(name: "CardComponent") do
          stimulus { values open: false }
        end
        assert_includes render(klass.new), 'data-card-component-open-value="false"'
      end

      def test_values_proc_evaluated_in_instance
        klass = define_component(name: "CardComponent") do
          prop :title, String, default: "Ruby"
          stimulus { values title: -> { @title.upcase } }
        end
        assert_includes render(klass.new), 'data-card-component-title-value="RUBY"'
      end

      def test_values_proc_returning_nil_drops_the_attribute
        klass = define_component(name: "CardComponent") do
          stimulus { values maybe: -> {} }
        end
        refute_match(/maybe-value/, render(klass.new))
      end

      def test_values_static_nil_drops_the_attribute
        klass = define_component(name: "CardComponent") do
          stimulus { values missing: nil }
        end
        refute_match(/missing-value/, render(klass.new))
      end

      def test_values_name_is_kebab_cased_in_attribute
        klass = define_component(name: "CardComponent") do
          stimulus { values api_url: "/x" }
        end
        assert_includes render(klass.new), 'data-card-component-api-url-value="/x"'
      end

      # ---- values_from_props ---------------------------------------------

      def test_values_from_props_mirrors_prop_ivar
        klass = define_component(name: "CardComponent") do
          prop :release_id, Integer, default: 7
          stimulus { values_from_props :release_id }
        end
        assert_includes render(klass.new), 'data-card-component-release-id-value="7"'
      end

      # ---- params ---------------------------------------------------------

      def test_params_static_hash
        klass = define_component(name: "ButtonComponent") do
          stimulus { params kind: "promote" }
        end
        assert_includes render(klass.new), 'data-button-component-kind-param="promote"'
      end

      def test_params_proc_evaluated_in_instance
        klass = define_component(name: "ButtonComponent") do
          prop :item_id, Integer, default: 123
          stimulus { params item_id: -> { @item_id } }
        end
        assert_includes render(klass.new), 'data-button-component-item-id-param="123"'
      end

      # ---- classes --------------------------------------------------------

      def test_classes_static_hash
        klass = define_component(name: "PanelComponent") do
          stimulus { classes loading: "opacity-50 cursor-wait" }
        end
        assert_includes render(klass.new), 'data-panel-component-loading-class="opacity-50 cursor-wait"'
      end

      def test_classes_proc_resolved_in_instance
        klass = define_component(name: "PanelComponent") do
          prop :status, Symbol, default: :ok
          stimulus { classes status: -> { (@status == :ok) ? "ok-class" : "err-class" } }
        end
        assert_includes render(klass.new), 'data-panel-component-status-class="ok-class"'
      end

      # ---- outlets --------------------------------------------------------

      def test_outlets_hash_with_selector
        klass = define_component(name: "PageComponent") do
          stimulus { outlets modal: ".modal" }
        end
        assert_includes render(klass.new), 'data-page-component-modal-outlet=".modal"'
      end

      def test_outlets_positional_hash_for_namespaced_identifier
        klass = define_component(name: "PageComponent") do
          stimulus { outlets({"admin--users" => ".admin"}) }
        end
        assert_includes render(klass.new), 'data-page-component-admin--users-outlet=".admin"'
      end
    end
  end
end
