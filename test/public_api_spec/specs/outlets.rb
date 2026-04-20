# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: all outlet input shapes (bare Symbol, String, 2-Array,
    # 3-Array, component instance), the `stimulus_outlet_host:` prop
    # self-registration pattern, and the outlets-DSL-does-not-evaluate-procs
    # semantic. Outlet attribute name is `data-<controller>-<name>-outlet`;
    # selector rules differ per input shape (auto-built vs. verbatim).
    module Outlets
      # ---- Hash DSL (simplest form) --------------------------------------

      def test_outlets_hash_string_selector
        klass = define_component(name: "PageComponent") do
          stimulus { outlets modal: ".modal" }
        end
        assert_includes render(klass.new),
          'data-page-component-modal-outlet=".modal"'
      end

      def test_outlets_hash_key_snake_case_becomes_kebab_case
        klass = define_component(name: "PageComponent") do
          stimulus { outlets user_status: "[data-controller='user-status']" }
        end
        assert_match(/data-page-component-user-status-outlet=/, render(klass.new))
      end

      def test_outlets_positional_hash_for_namespaced_identifier
        # Identifiers that can't be Ruby kwarg keys (contain `--`)
        klass = define_component(name: "PageComponent") do
          stimulus { outlets({"admin--users" => ".admin"}) }
        end
        assert_includes render(klass.new),
          'data-page-component-admin--users-outlet=".admin"'
      end

      # ---- stimulus_outlets: prop / root_element_attributes --------------

      def test_outlets_from_bare_symbol_uses_auto_selector
        # SKILL §1.7 L244: `:user_status` → auto-selector
        #   `[data-controller~=user-status]`
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [:user_status]} }
        end
        assert_includes render(klass.new),
          'data-page-component-user-status-outlet="[data-controller~=user-status]"'
      end

      def test_outlets_from_array_pair_name_and_selector
        # [outlet_identifier, css_selector]
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [[:tab, ".tabs"]]} }
        end
        assert_includes render(klass.new),
          'data-page-component-tab-outlet=".tabs"'
      end

      def test_outlets_from_array_triple_cross_controller
        # [controller, outlet_name, selector]
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) do
            {stimulus_outlets: [["admin/users", :row, ".user-row"]]}
          end
        end
        assert_includes render(klass.new),
          'data-admin--users-row-outlet=".user-row"'
      end

      def test_outlets_from_component_instance_scopes_with_host_id
        # Passing a child component instance yields
        # "#<host-id> [data-controller~=<child-identifier>]"
        child_klass = define_component(name: "CardComponent")
        host_klass = define_component(name: "PageComponent")

        host = host_klass.new(id: "page-1")
        child = child_klass.new
        host.add_stimulus_outlets(child)

        assert_includes render(host),
          'data-page-component-card-component-outlet="#page-1 [data-controller~=card-component]"'
      end

      # ---- outlets DSL does NOT evaluate procs ---------------------------

      def test_outlets_dsl_proc_values_raise_not_silently_passed_through
        # SPEC-NOTE (audit gap G13): outlets is the only DSL primitive
        # that skips proc resolution (stimulus_builder.rb:91 returns
        # entries.dup untouched). A proc value therefore reaches the
        # parser, which rejects it — ArgumentError raised at `.new()`
        # time. Vident 2.0 may either add proc support or raise earlier.
        klass = define_component(name: "PageComponent") do
          stimulus { outlets modal: -> { ".modal" } }
        end
        error = assert_raises(ArgumentError) { klass.new }
        assert_match(/Invalid argument types/, error.message)
      end

      # ---- stimulus_outlet_host: self-registration -----------------------

      def test_stimulus_outlet_host_registers_child_on_parent
        child_klass = define_component(name: "ReleaseCardComponent")
        host_klass = define_component(name: "PageComponent")

        host = host_klass.new(id: "page-abc")
        # Instantiating the child with a host triggers
        # host.add_stimulus_outlets(child) during the child's init.
        child_klass.new(stimulus_outlet_host: host)

        assert_includes render(host),
          'data-page-component-release-card-component-outlet="#page-abc [data-controller~=release-card-component]"'
      end

      def test_stimulus_outlet_host_works_when_parent_has_no_dsl_outlets
        child_klass = define_component(name: "ReleaseCardComponent")
        host_klass = define_component(name: "PageComponent")
        host = host_klass.new(id: "page-xyz")
        child_klass.new(stimulus_outlet_host: host)
        assert_match(
          /data-page-component-release-card-component-outlet="#page-xyz \[data-controller~=release-card-component\]"/,
          render(host)
        )
      end

      def test_multiple_children_register_multiple_outlets_on_same_host
        child_a_klass = define_component(name: "CardAComponent")
        child_b_klass = define_component(name: "CardBComponent")
        host_klass = define_component(name: "PageComponent")
        host = host_klass.new(id: "p")
        child_a_klass.new(stimulus_outlet_host: host)
        child_b_klass.new(stimulus_outlet_host: host)
        html = render(host)
        assert_includes html,
          'data-page-component-card-a-component-outlet="#p [data-controller~=card-a-component]"'
        assert_includes html,
          'data-page-component-card-b-component-outlet="#p [data-controller~=card-b-component]"'
      end

      def test_outlet_host_child_without_host_renders_normally
        child_klass = define_component(name: "ReleaseCardComponent")
        child = child_klass.new
        assert_kind_of child_klass, child
        refute_match(/-outlet=/, render(child))
      end
    end
  end
end
