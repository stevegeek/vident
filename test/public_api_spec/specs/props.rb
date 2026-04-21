# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: each `stimulus_*:` prop at .new() accepting its full union
    # type per stimulus_component.rb:44-57. Same data reaching the DOM
    # as when declared via the DSL. Also: stimulus_* inside
    # root_element_attributes as the merge-with-DSL path.
    module Props
      # ---- stimulus_actions: prop ----------------------------------------

      def test_stimulus_actions_prop_symbol
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(stimulus_actions: [:click]))
        assert_includes html, 'data-action="button-component#click"'
      end

      def test_stimulus_actions_prop_array_pair
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(stimulus_actions: [[:click, :handle]]))
        assert_includes html, 'data-action="click->button-component#handle"'
      end

      def test_stimulus_actions_prop_hash_descriptor
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(stimulus_actions: [{event: :click, method: :submit, options: [:once]}]))
        assert_includes html, 'data-action="click:once->button-component#submit"'
      end

      def test_stimulus_actions_prop_via_root_element_attributes_merges_with_dsl
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions :hover }
          define_method(:root_element_attributes) { {stimulus_actions: [:click]} }
        end
        assert_includes render(klass.new),
          'data-action="button-component#hover button-component#click"'
      end

      # ---- stimulus_targets: prop ----------------------------------------

      def test_stimulus_targets_prop_symbol
        klass = define_component(name: "FormComponent")
        html = render(klass.new(stimulus_targets: [:input]))
        assert_includes html, 'data-form-component-target="input"'
      end

      def test_stimulus_targets_prop_cross_controller_array
        klass = define_component(name: "FormComponent")
        html = render(klass.new(stimulus_targets: [["admin/users", :row]]))
        assert_includes html, 'data-admin--users-target="row"'
      end

      # ---- stimulus_values: prop -----------------------------------------

      def test_stimulus_values_prop_hash
        klass = define_component(name: "CardComponent")
        html = render(klass.new(stimulus_values: {title: "X"}))
        assert_includes html, 'data-card-component-title-value="X"'
      end

      def test_stimulus_values_prop_array_for_cross_controller
        klass = define_component(name: "CardComponent")
        html = render(klass.new(stimulus_values: [["other/ctrl", :foo, "bar"]]))
        assert_includes html, 'data-other--ctrl-foo-value="bar"'
      end

      # ---- stimulus_params: prop -----------------------------------------

      def test_stimulus_params_prop_hash
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(stimulus_params: {kind: "promote"}))
        assert_includes html, 'data-button-component-kind-param="promote"'
      end

      # ---- stimulus_classes: prop ----------------------------------------

      def test_stimulus_classes_prop_hash
        klass = define_component(name: "PanelComponent")
        html = render(klass.new(stimulus_classes: {loading: "opacity-50"}))
        assert_includes html, 'data-panel-component-loading-class="opacity-50"'
      end

      # ---- pre-built value objects ---------------------------------------

      def test_stimulus_actions_prop_accepts_pre_built_value
        klass = define_component(name: "ButtonComponent")
        comp = klass.new
        action = comp.stimulus_action(:click)
        html = render(klass.new(stimulus_actions: [action]))
        assert_includes html, 'data-action="button-component#click"'
      end

      # ---- _Boolean prop does NOT auto-generate `NAME?` predicate --------

      # SPEC-NOTE (doc error flagged during spec extraction): SKILL.md L231
      # (and older context/ docs) claim `prop :open, _Boolean` "generates an
      # `open?` predicate". It does not. Literal does not install a `?`-
      # suffixed method for Boolean props even with `reader: :public`. This
      # test locks what actually happens; the docs should be corrected.
      def test_boolean_prop_does_not_generate_predicate_method
        klass = define_component(name: "ButtonComponent") do
          prop :featured, _Boolean, default: false, reader: :public
        end
        comp = klass.new(featured: true)
        refute_respond_to comp, :featured?
        assert comp.featured  # plain reader works
      end

      # ---- stimulus_outlet_host is a nilable prop on every component -----

      def test_stimulus_outlet_host_prop_exists_on_every_component
        klass = define_component(name: "FooComponent")
        assert_includes klass.prop_names, :stimulus_outlet_host
      end

      def test_stimulus_outlet_host_default_nil
        klass = define_component(name: "FooComponent")
        assert_nil klass.new.instance_variable_get(:@stimulus_outlet_host)
      end
    end
  end
end
