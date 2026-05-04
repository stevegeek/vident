# frozen_string_literal: true

module Vident
  module PublicApiSpec
    module Outlets
      def test_outlets_hash_explicit_selector
        klass = define_component(name: "PageComponent") do
          stimulus { outlets modal: Vident::Selector(".modal") }
        end
        assert_includes render(klass.new),
          'data-page-component-modal-outlet=".modal"'
      end

      def test_outlets_hash_nil_value_is_auto_selector
        klass = define_component(name: "PageComponent") do
          stimulus { outlets user_status: nil }
        end
        assert_match(
          /data-page-component-user-status-outlet="#page-component-[^\s"]+\s\[data-controller~=user-status\]"/,
          render(klass.new)
        )
      end

      def test_outlets_hash_raw_string_value_raises
        e = assert_raises(::Vident::ParseError) do
          define_component(name: "PageComponent") do
            stimulus { outlets modal: ".modal" }
          end
        end
        assert_includes e.message, "Vident::Selector"
      end

      def test_outlets_positional_hash_for_namespaced_identifier
        klass = define_component(name: "PageComponent") do
          stimulus { outlets({"admin--users" => Vident::Selector(".admin")}) }
        end
        assert_includes render(klass.new),
          'data-page-component-admin--users-outlet=".admin"'
      end

      def test_outlets_positional_hash_nil_value_is_auto_selector
        klass = define_component(name: "PageComponent") do
          stimulus { outlets({"admin--users" => nil}) }
        end
        assert_match(
          /data-page-component-admin--users-outlet="#page-component-[^\s"]+\s\[data-controller~=admin--users\]"/,
          render(klass.new)
        )
      end

      def test_outlets_from_bare_symbol_uses_auto_selector
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [:user_status]} }
        end
        html = render(klass.new)
        assert_match(/data-page-component-user-status-outlet="#page-component-[^\s"]+\s\[data-controller~=user-status\]"/, html)
      end

      def test_outlets_from_bare_symbol_auto_selector_scopes_by_explicit_id
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [:user_status]} }
        end
        html = render(klass.new(id: "my-page"))
        assert_includes html,
          'data-page-component-user-status-outlet="#my-page [data-controller~=user-status]"'
      end

      def test_outlets_from_array_pair_with_selector
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [[:tab, Vident::Selector(".tabs")]]} }
        end
        assert_includes render(klass.new),
          'data-page-component-tab-outlet=".tabs"'
      end

      def test_outlets_prop_array_with_raw_string_selector_raises
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [[:tab, ".tabs"]]} }
        end
        e = assert_raises(::Vident::ParseError) { render(klass.new) }
        assert_includes e.message, "Vident::Selector"
      end

      def test_outlets_prop_top_level_string_with_selector_chars_raises
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) { {stimulus_outlets: [".modal"]} }
        end
        e = assert_raises(::Vident::ParseError) { render(klass.new) }
        assert_includes e.message, "Vident::Selector"
      end

      def test_outlets_from_array_triple_cross_controller
        klass = define_component(name: "PageComponent") do
          define_method(:root_element_attributes) do
            {stimulus_outlets: [["admin/users", :row, Vident::Selector(".user-row")]]}
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
