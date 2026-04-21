# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: what currently raises what. Locks the shapes today's code
    # emits so the Vident 2.0 synthesis (which proposes a typed
    # Vident::ParseError / DeclarationError / RenderError / StateError
    # hierarchy) can be tracked against current ArgumentError /
    # StandardError / NoMethodError behaviour. Other spec modules already
    # cover raises in their own contexts (outlets.rb for outlet proc,
    # controllers.rb for no-controller, child_element.rb for plural-
    # enum). This file catches the rest.
    module Errors
      # ---- unknown action option symbol ----------------------------------

      # V1 raises ArgumentError; V2 raises the typed Vident2::ParseError
      # (which doesn't inherit from ArgumentError). Each test asserts its
      # adapter's current behaviour.

      def test_unknown_action_option_symbol_raises
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions({event: :click, method: :submit, options: [:bogus_modifier]}) }
        end
        expected = (vident_version == :v2) ? ::Vident2::ParseError : ArgumentError
        error = assert_raises(expected) { klass.new }
        assert_match(/Invalid option|bogus_modifier/i, error.message)
      end

      def test_action_numeric_argument_raises
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions 42 }
        end
        expected = (vident_version == :v2) ? ::Vident2::ParseError : ArgumentError
        assert_raises(expected) { klass.new }
      end

      def test_action_four_args_raises
        klass = define_component(name: "ButtonComponent")
        expected = (vident_version == :v2) ? ::Vident2::ParseError : ArgumentError
        assert_raises(expected) { klass.new.stimulus_action(:a, :b, :c, :d) }
      end

      # ---- invalid HTML tag (Phlex) -------------------------------------

      def test_phlex_root_element_invalid_tag_raises
        # Phlex guards element_tag against a VALID_TAGS whitelist. VC has no
        # such guard (browsers will accept any tag name).
        klass = define_component(name: "FooComponent")
        if component_base.name == "Vident::Phlex::HTML"
          assert_raises(ArgumentError) { render(klass.new(element_tag: :bogus_tag)) }
        else
          skip "Phlex-only: root tag whitelist not enforced by VC adapter"
        end
      end

      def test_phlex_child_element_invalid_tag_raises
        klass = define_component(name: "FooComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) { root_element { child_element(:bogus_tag) } }
          else
            define_method(:call) { root_element { child_element(:bogus_tag) } }
          end
        end
        if component_base.name == "Vident::Phlex::HTML"
          assert_raises(ArgumentError) { render(klass.new) }
        else
          skip "Phlex-only: child tag whitelist not enforced by VC adapter"
        end
      end
    end
  end
end
