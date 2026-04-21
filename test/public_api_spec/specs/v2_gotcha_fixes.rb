# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # V2-only counterparts to V1-locking tests in the shared spec modules.
    # Each test here asserts the V2 behaviour that replaces one V1 gotcha
    # (see doc/reviews/v1-gotchas.md). Included only by V2 runners; skipped
    # on V1 via `skip_on_v1` guards.
    module V2GotchaFixes
      # ---- #1 mutator Array = single entry -----------------------------

      def test_add_stimulus_actions_array_treated_as_single_entry
        skip_on_v1 "V1 splats Array into multiple actions"
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) { add_stimulus_actions([:click, :hover]) }
        end
        assert_includes render(klass.new), 'data-action="click->button-component#hover"'
      end

      # ---- #2 controller prop appends to implied -----------------------

      def test_stimulus_controllers_prop_appends_to_implied
        skip_on_v1 "V1 replaces implied with prop"
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(stimulus_controllers: ["tooltip"]))
        assert_includes html, 'data-controller="button-component tooltip"'
      end

      def test_stimulus_controllers_prop_with_pre_built_appends
        skip_on_v1 "V1 replaces implied with prop"
        klass = define_component(name: "PanelComponent")
        ctrl = klass.new.stimulus_controller("tooltip")
        html = render(klass.new(stimulus_controllers: [ctrl]))
        assert_includes html, 'data-controller="panel-component tooltip"'
      end

      # ---- #3 outlets DSL evaluates procs ------------------------------

      def test_outlets_dsl_proc_evaluated_in_instance
        skip_on_v1 "V1 short-circuits outlet proc resolution"
        klass = define_component(name: "PageComponent") do
          prop :where, String, default: ".modal"
          stimulus { outlets modal: -> { @where } }
        end
        html = render(klass.new(where: ".custom-modal"))
        assert_includes html, 'data-page-component-modal-outlet=".custom-modal"'
      end

      # ---- #4 no_stimulus_controller + DSL = DeclarationError ----------

      def test_no_stimulus_controller_with_dsl_raises_declaration_error
        skip_on_v1 "V1 raises bare StandardError at instance init"
        error = assert_raises(::Vident2::DeclarationError) do
          define_component(name: "AvatarComponent") do
            no_stimulus_controller
            stimulus { actions :click }
          end
        end
        assert_match(/no_stimulus_controller/, error.message)
      end

      # ---- #5 unified Symbol keys on every #to_h -----------------------

      def test_stimulus_target_to_h_symbol_key
        skip_on_v1 "V1 returns String keys for per-item collections"
        klass = define_component(name: "FormComponent")
        assert_equal({:"form-component-target" => "input"},
          klass.new.stimulus_target(:input).to_h)
      end

      def test_stimulus_action_to_h_symbol_key
        skip_on_v1 "Action already used Symbol in V1 — this asserts consistency"
        klass = define_component(name: "ButtonComponent")
        assert_equal({action: "button-component#click"},
          klass.new.stimulus_action(:click).to_h)
      end

      def test_stimulus_controller_to_h_symbol_key
        skip_on_v1 "Controller already used Symbol in V1 — this asserts consistency"
        klass = define_component(name: "ButtonComponent")
        assert_equal({controller: "my-ctrl"},
          klass.new.stimulus_controller("my_ctrl").to_h)
      end

      def test_stimulus_value_to_h_symbol_key
        skip_on_v1 "V1 returns String keys"
        klass = define_component(name: "CardComponent")
        assert_equal({:"card-component-title-value" => "Hi"},
          klass.new.stimulus_value(:title, "Hi").to_h)
      end

      def test_stimulus_param_to_h_symbol_key
        skip_on_v1 "V1 returns String keys"
        klass = define_component(name: "ButtonComponent")
        assert_equal({:"button-component-item-id-param" => "42"},
          klass.new.stimulus_param(:item_id, 42).to_h)
      end

      def test_stimulus_class_to_h_symbol_key
        skip_on_v1 "V1 returns String keys"
        klass = define_component(name: "PanelComponent")
        assert_equal({:"panel-component-loading-class" => "opacity-50"},
          klass.new.stimulus_class(:loading, "opacity-50").to_h)
      end

      def test_stimulus_targets_collection_to_h_symbol_key
        skip_on_v1 "V1 uses String keys for Target collection"
        klass = define_component(name: "FormComponent")
        assert_equal({:"form-component-target" => "a b"},
          klass.new.stimulus_targets(:a, :b).to_h)
      end

      def test_stimulus_values_collection_to_h_symbol_keys
        skip_on_v1 "V1 uses String keys for Value collection"
        klass = define_component(name: "CardComponent")
        h = klass.new.stimulus_values(count: 1, label: "x").to_h
        assert_equal "1", h[:"card-component-count-value"]
        assert_equal "x", h[:"card-component-label-value"]
      end

      # ---- #7 only nil drops; false survives --------------------------

      def test_action_proc_returning_false_reaches_parser_and_raises
        skip_on_v1 "V1 silently drops via blank? filter"
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions(-> { false }) }
        end
        # V2 defers proc resolution to render; the raise fires when the
        # adapter's before_template / before_render runs the procs.
        assert_raises(::Vident2::ParseError) { render(klass.new) }
      end

      # ---- V2 type references -----------------------------------------

      def test_stimulus_target_returns_vident2_type
        skip_on_v1 "V2 types live under Vident2::Stimulus::*"
        klass = define_component(name: "FormComponent")
        assert_kind_of ::Vident2::Stimulus::Target, klass.new.stimulus_target(:input)
      end

      def test_stimulus_action_returns_vident2_type
        skip_on_v1 "V2 types live under Vident2::Stimulus::*"
        klass = define_component(name: "ButtonComponent")
        assert_kind_of ::Vident2::Stimulus::Action, klass.new.stimulus_action(:click)
      end

      def test_stimulus_controller_returns_vident2_type
        skip_on_v1 "V2 types live under Vident2::Stimulus::*"
        klass = define_component(name: "ButtonComponent")
        assert_kind_of ::Vident2::Stimulus::Controller, klass.new.stimulus_controller("my_ctrl")
      end

      def test_stimulus_value_returns_vident2_type
        skip_on_v1 "V2 types live under Vident2::Stimulus::*"
        klass = define_component(name: "CardComponent")
        assert_kind_of ::Vident2::Stimulus::Value, klass.new.stimulus_value(:title, "Hi")
      end

      def test_stimulus_outlet_returns_vident2_type
        skip_on_v1 "V2 types live under Vident2::Stimulus::*"
        klass = define_component(name: "PageComponent")
        assert_kind_of ::Vident2::Stimulus::Outlet, klass.new.stimulus_outlet(:tab, ".tab")
      end

      def test_stimulus_targets_returns_parametric_collection
        skip_on_v1 "V2 uses a single parametric Collection class"
        klass = define_component(name: "FormComponent")
        assert_kind_of ::Vident2::Stimulus::Collection, klass.new.stimulus_targets(:a, :b)
      end
    end
  end
end
