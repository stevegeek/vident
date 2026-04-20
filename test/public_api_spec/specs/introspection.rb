# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: user-facing introspection methods on components — clone,
    # inspect, prop_names, outlet_id, default_controller_path. These are
    # documented public API (component.rb + stimulus_component.rb) and
    # users rely on their return shapes for composition (outlet_id in
    # outlet selectors, prop_names in generic prop introspection, clone
    # for prop-override forking).
    module Introspection
      # ---- prop_names -----------------------------------------------------

      def test_prop_names_class_method_returns_symbol_list
        klass = define_component(name: "ButtonComponent") do
          prop :title, String, default: "x"
        end
        names = klass.prop_names
        assert_kind_of Array, names
        assert(names.all? { |n| n.is_a?(Symbol) })
        assert_includes names, :title
      end

      def test_prop_names_includes_base_props
        klass = define_component(name: "ButtonComponent")
        names = klass.prop_names
        %i[element_tag id classes html_options].each do |built_in|
          assert_includes names, built_in, "expected base prop #{built_in.inspect} in prop_names"
        end
      end

      def test_prop_names_includes_stimulus_props
        klass = define_component(name: "ButtonComponent")
        names = klass.prop_names
        %i[
          stimulus_controllers
          stimulus_actions
          stimulus_targets
          stimulus_outlets
          stimulus_outlet_host
          stimulus_values
          stimulus_params
          stimulus_classes
        ].each do |stim_prop|
          assert_includes names, stim_prop, "expected stimulus prop #{stim_prop.inspect} in prop_names"
        end
      end

      def test_prop_names_instance_delegates_to_class
        klass = define_component(name: "ButtonComponent")
        assert_equal klass.prop_names, klass.new.prop_names
      end

      # ---- clone ----------------------------------------------------------

      def test_clone_returns_new_distinct_instance
        klass = define_component(name: "ButtonComponent") do
          prop :title, String, default: "x"
        end
        original = klass.new(title: "A")
        cloned = original.clone
        refute_same original, cloned
        assert_kind_of klass, cloned
      end

      def test_clone_without_overrides_preserves_props
        klass = define_component(name: "ButtonComponent") do
          prop :title, String, default: "x"
        end
        original = klass.new(title: "A")
        cloned = original.clone
        assert_equal "A", cloned.instance_variable_get(:@title)
      end

      def test_clone_with_overrides_merges
        klass = define_component(name: "ButtonComponent") do
          prop :title, String, default: "x"
          prop :url, _Nilable(String)
        end
        original = klass.new(title: "A", url: "/a")
        cloned = original.clone(title: "B")
        assert_equal "B", cloned.instance_variable_get(:@title)
        assert_equal "/a", cloned.instance_variable_get(:@url)
        # Original unchanged
        assert_equal "A", original.instance_variable_get(:@title)
      end

      # ---- inspect --------------------------------------------------------

      def test_inspect_includes_class_name
        klass = define_component(name: "ButtonComponent") do
          prop :title, String, default: "x"
        end
        result = klass.new(title: "Hello").inspect
        assert_match(/ButtonComponent/, result)
      end

      def test_inspect_includes_props
        klass = define_component(name: "ButtonComponent") do
          prop :title, String, default: "x"
        end
        result = klass.new(title: "Hello").inspect
        assert_match(/title="Hello"/, result)
      end

      def test_inspect_wraps_with_vident_label
        klass = define_component(name: "ButtonComponent")
        assert_match(/<Vident::Component>/, klass.new.inspect)
      end

      # ---- outlet_id ------------------------------------------------------

      def test_outlet_id_returns_identifier_and_hash_prefixed_id
        klass = define_component(name: "CardComponent")
        comp = klass.new(id: "my-card")
        assert_equal ["card-component", "#my-card"], comp.outlet_id
      end

      def test_outlet_id_memoized
        klass = define_component(name: "CardComponent")
        comp = klass.new(id: "my-card")
        assert_same comp.outlet_id, comp.outlet_id
      end

      def test_outlet_id_works_with_auto_generated_id
        klass = define_component(name: "CardComponent")
        comp = klass.new
        identifier, hash_id = comp.outlet_id
        assert_equal "card-component", identifier
        assert_match(/\A#card-component-/, hash_id)
      end

      # ---- default_controller_path ---------------------------------------

      def test_default_controller_path_is_underscored_class_path
        klass = define_component(name: "Admin::UserCardComponent")
        assert_equal "admin/user_card_component",
          klass.new.send(:default_controller_path)
      end
    end
  end
end
