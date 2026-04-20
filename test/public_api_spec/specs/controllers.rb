# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: implied controller auto-attachment, no_stimulus_controller
    # opt-out, stimulus_controllers: prop, component_name /
    # stimulus_identifier / default_controller_path, path conversion
    # semantics (namespace → `--`, CamelCase → kebab, snake_case → dash).
    module Controllers
      # ---- implied controller emitted on root -----------------------------

      def test_implied_controller_auto_attached_to_root
        klass = define_component(name: "ButtonComponent")
        assert_includes render(klass.new), 'data-controller="button-component"'
      end

      def test_implied_controller_emitted_as_root_class
        klass = define_component(name: "ButtonComponent")
        assert_match(/class="[^"]*button-component[^"]*"/, render(klass.new))
      end

      # ---- path conversion ------------------------------------------------

      def test_namespace_class_uses_dash_dash_separator
        klass = define_component(name: "Admin::UserCardComponent")
        assert_includes render(klass.new),
          'data-controller="admin--user-card-component"'
      end

      def test_deep_namespace_nesting
        klass = define_component(name: "A::B::MyComponent")
        assert_includes render(klass.new),
          'data-controller="a--b--my-component"'
      end

      # ---- class / instance accessors -------------------------------------

      def test_component_name_class_method
        klass = define_component(name: "PanelComponent")
        assert_equal "panel-component", klass.component_name
      end

      def test_stimulus_identifier_class_method
        klass = define_component(name: "PanelComponent")
        assert_equal "panel-component", klass.stimulus_identifier
      end

      def test_stimulus_identifier_instance_matches_class
        klass = define_component(name: "PanelComponent")
        assert_equal "panel-component", klass.new.stimulus_identifier
      end

      def test_component_name_instance_matches_class
        klass = define_component(name: "PanelComponent")
        assert_equal "panel-component", klass.new.component_name
      end

      def test_default_controller_path_returns_underscored_path
        klass = define_component(name: "Admin::UserCardComponent")
        assert_equal "admin/user_card_component",
          klass.new.send(:default_controller_path)
      end

      def test_anonymous_class_falls_back_to_anonymous_component_identifier
        klass = Class.new(component_base)
        assert_equal "anonymous-component", klass.stimulus_identifier
      end

      def test_stimulus_identifier_from_path_public_module_function
        assert_equal "admin--users",
          ::Vident::StimulusComponent.stimulus_identifier_from_path("admin/users")
        assert_equal "my-controller",
          ::Vident::StimulusComponent.stimulus_identifier_from_path("my_controller")
        assert_equal "a--b--c",
          ::Vident::StimulusComponent.stimulus_identifier_from_path("a/b/c")
      end

      # ---- no_stimulus_controller opt-out --------------------------------

      def test_no_stimulus_controller_predicate
        klass = define_component(name: "AvatarComponent") { no_stimulus_controller }
        refute klass.stimulus_controller?
      end

      def test_stimulus_controller_predicate_true_by_default
        klass = define_component(name: "ButtonComponent")
        assert klass.stimulus_controller?
      end

      def test_no_stimulus_controller_omits_data_controller_attribute
        klass = define_component(name: "AvatarComponent") { no_stimulus_controller }
        refute_match(/data-controller=/, render(klass.new))
      end

      def test_no_stimulus_controller_with_dsl_emission_raises
        # SPEC-NOTE (sharp edge): when no_stimulus_controller is declared,
        # the `stimulus do` DSL has nothing to route entries to, and the
        # resolver raises a bare StandardError at .new() time. Task 16
        # (errors) may re-home this to a typed Vident error in 2.0.
        klass = define_component(name: "AvatarComponent") do
          no_stimulus_controller
          stimulus { actions :click }
        end
        error = assert_raises(StandardError) { klass.new }
        assert_match(/No controllers have been specified/, error.message)
      end

      # ---- stimulus_controllers: prop ------------------------------------

      def test_stimulus_controllers_prop_at_new_replaces_implied
        # SPEC-NOTE: passing the prop at .new() is direct assignment (no
        # merge with default). The implied controller is the *default*,
        # not an unconditional addition. Compare
        # test_stimulus_controllers_via_root_element_attributes_additive
        # below for the merge path.
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(stimulus_controllers: ["tooltip"]))
        assert_includes html, 'data-controller="tooltip"'
        refute_match(/data-controller="[^"]*button-component[^"]*"/, html)
      end

      def test_stimulus_controllers_via_root_element_attributes_additive
        klass = define_component(name: "ButtonComponent") do
          define_method(:root_element_attributes) { {stimulus_controllers: ["tooltip"]} }
        end
        assert_includes render(klass.new),
          'data-controller="button-component tooltip"'
      end

      def test_stimulus_controllers_symbol_path
        # G32: Symbol `:"admin/users"` should behave like String "admin/users"
        klass = define_component(name: "ButtonComponent") do
          define_method(:root_element_attributes) { {stimulus_controllers: [:"admin/users"]} }
        end
        assert_includes render(klass.new),
          'data-controller="button-component admin--users"'
      end
    end
  end
end
