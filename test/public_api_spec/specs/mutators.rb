# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: `add_stimulus_<kind>(input)` mutators — 7 methods generated
    # from `Stimulus::PRIMITIVES`. Their purpose is to let a component
    # add stimulus attributes at *runtime* (typically in
    # `after_component_initialize`) based on state that isn't knowable at
    # class-definition time.
    #
    # Mutators merge into whatever the DSL + props + `root_element_attributes`
    # already produced. Each input shape that the plural parser accepts
    # (Symbol / Array / Hash / pre-built Value / pre-built Collection)
    # flows through unchanged.
    module Mutators
      # ---- add_stimulus_actions ------------------------------------------

      def test_add_stimulus_actions_from_after_component_initialize
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) { add_stimulus_actions(:click) }
        end
        assert_includes render(klass.new), 'data-action="button-component#click"'
      end

      def test_add_stimulus_actions_merges_with_dsl
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions :hover }
          define_method(:after_component_initialize) { add_stimulus_actions(:click) }
        end
        assert_includes render(klass.new),
          'data-action="button-component#hover button-component#click"'
      end

      # SPEC-NOTE (splat semantics): the DSL's `actions [:click, :handle]`
      # treats the Array as ONE action-descriptor (event+method). The
      # mutator `add_stimulus_actions([:click, :handle])` splats the Array
      # so it becomes TWO symbol arguments — two separate actions. This
      # is not symmetric with the DSL. To pass an Array-shaped single
      # action through the mutator, wrap in a pre-built value
      # (`stimulus_action(:click, :handle)`) or double-wrap
      # (`add_stimulus_actions([[:click, :handle]])`).
      def test_add_stimulus_actions_splats_array_argument_into_multiple_actions
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) { add_stimulus_actions([:click, :hover]) }
        end
        assert_includes render(klass.new),
          'data-action="button-component#click button-component#hover"'
      end

      def test_add_stimulus_actions_accepts_pre_built_event_method_value
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) do
            add_stimulus_actions(stimulus_action(:click, :handle))
          end
        end
        assert_includes render(klass.new), 'data-action="click->button-component#handle"'
      end

      def test_add_stimulus_actions_accepts_pre_built_cross_controller_value
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) do
            add_stimulus_actions(stimulus_action(:click, "dialog/open", :show))
          end
        end
        assert_includes render(klass.new), 'data-action="click->dialog--open#show"'
      end

      def test_add_stimulus_actions_accepts_hash_descriptor
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) do
            add_stimulus_actions({event: :click, method: :submit, options: [:once]})
          end
        end
        assert_includes render(klass.new),
          'data-action="click:once->button-component#submit"'
      end

      def test_add_stimulus_actions_accepts_pre_built_value
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) do
            add_stimulus_actions(stimulus_action(:click))
          end
        end
        assert_includes render(klass.new), 'data-action="button-component#click"'
      end

      def test_add_stimulus_actions_multiple_calls_accumulate
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) do
            add_stimulus_actions(:click)
            add_stimulus_actions(:hover)
          end
        end
        assert_includes render(klass.new),
          'data-action="button-component#click button-component#hover"'
      end

      def test_add_stimulus_actions_branches_on_prop_state
        klass = define_component(name: "ButtonComponent") do
          prop :admin, _Boolean, default: false
          define_method(:after_component_initialize) do
            add_stimulus_actions(:delete) if @admin
          end
        end
        refute_match(/#delete/, render(klass.new(admin: false)))
        assert_includes render(klass.new(admin: true)),
          'data-action="button-component#delete"'
      end

      # ---- add_stimulus_targets ------------------------------------------

      def test_add_stimulus_targets_from_after_component_initialize
        klass = define_component(name: "FormComponent") do
          define_method(:after_component_initialize) { add_stimulus_targets(:input) }
        end
        assert_includes render(klass.new), 'data-form-component-target="input"'
      end

      def test_add_stimulus_targets_merges_with_dsl_same_controller
        klass = define_component(name: "FormComponent") do
          stimulus { targets :output }
          define_method(:after_component_initialize) { add_stimulus_targets(:input) }
        end
        assert_includes render(klass.new),
          'data-form-component-target="output input"'
      end

      # ---- add_stimulus_values -------------------------------------------

      def test_add_stimulus_values_hash
        klass = define_component(name: "CardComponent") do
          define_method(:after_component_initialize) { add_stimulus_values(label: "hello") }
        end
        assert_includes render(klass.new), 'data-card-component-label-value="hello"'
      end

      def test_add_stimulus_values_merges_with_dsl
        klass = define_component(name: "CardComponent") do
          stimulus { values count: 1 }
          define_method(:after_component_initialize) { add_stimulus_values(label: "hello") }
        end
        html = render(klass.new)
        assert_includes html, 'data-card-component-count-value="1"'
        assert_includes html, 'data-card-component-label-value="hello"'
      end

      # ---- add_stimulus_params -------------------------------------------

      def test_add_stimulus_params_hash
        klass = define_component(name: "ButtonComponent") do
          define_method(:after_component_initialize) { add_stimulus_params(kind: "promote") }
        end
        assert_includes render(klass.new), 'data-button-component-kind-param="promote"'
      end

      # ---- add_stimulus_classes ------------------------------------------

      def test_add_stimulus_classes_hash
        klass = define_component(name: "PanelComponent") do
          define_method(:after_component_initialize) { add_stimulus_classes(loading: "opacity-50") }
        end
        assert_includes render(klass.new),
          'data-panel-component-loading-class="opacity-50"'
      end

      # ---- add_stimulus_outlets ------------------------------------------

      def test_add_stimulus_outlets_hash
        klass = define_component(name: "PageComponent") do
          define_method(:after_component_initialize) { add_stimulus_outlets(modal: ".modal") }
        end
        assert_includes render(klass.new),
          'data-page-component-modal-outlet=".modal"'
      end

      # ---- add_stimulus_controllers --------------------------------------

      def test_add_stimulus_controllers_string
        klass = define_component(name: "PanelComponent") do
          define_method(:after_component_initialize) { add_stimulus_controllers("tooltip") }
        end
        assert_includes render(klass.new), 'data-controller="panel-component tooltip"'
      end

      def test_add_stimulus_controllers_accepts_pre_built_collection
        klass = define_component(name: "PanelComponent") do
          define_method(:after_component_initialize) do
            add_stimulus_controllers(stimulus_controllers("extra"))
          end
        end
        assert_includes render(klass.new), 'data-controller="panel-component extra"'
      end
    end
  end
end
