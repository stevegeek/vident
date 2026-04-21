# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: what currently raises what — typed error hierarchy and runtime
    # raise shapes. Other spec modules cover context-specific raises (outlets.rb,
    # controllers.rb, child_element.rb). This file covers the hierarchy and
    # parse/action raises.
    module Errors
      # ---- ParseError hierarchy ------------------------------------------

      def test_parse_error_is_sibling_of_declaration_error
        assert_operator ::Vident::ParseError, :<, ::Vident::Error
        refute_operator ::Vident::ParseError, :<, ::Vident::DeclarationError
      end

      def test_parse_error_and_declaration_error_are_distinct_siblings
        refute_equal ::Vident::ParseError, ::Vident::DeclarationError
        assert_operator ::Vident::DeclarationError, :<, ::Vident::Error
      end

      # ---- included-do composition guards --------------------------------

      def test_stimulus_parsing_without_identifiable_raises_declaration_error
        err = assert_raises(::Vident::DeclarationError) do
          Class.new { include ::Vident::Capabilities::StimulusParsing }
        end
        assert_match(/Identifiable/, err.message)
      end

      def test_stimulus_parsing_anonymous_class_message_does_not_say_nil
        err = assert_raises(::Vident::DeclarationError) do
          Class.new { include ::Vident::Capabilities::StimulusParsing }
        end
        refute_match(/\bnil\b/, err.message)
        assert_match(/anonymous component/, err.message)
      end

      def test_stimulus_mutation_without_identifiable_raises_declaration_error
        err = assert_raises(::Vident::DeclarationError) do
          Class.new { include ::Vident::Capabilities::StimulusMutation }
        end
        assert_match(/Identifiable/, err.message)
      end

      def test_stimulus_mutation_anonymous_class_message_does_not_say_nil
        err = assert_raises(::Vident::DeclarationError) do
          Class.new { include ::Vident::Capabilities::StimulusMutation }
        end
        refute_match(/\bnil\b/, err.message)
        assert_match(/anonymous component/, err.message)
      end

      # ---- unknown action option symbol ----------------------------------

      # V1 raises ArgumentError; V2 raises the typed Vident::ParseError
      # (which doesn't inherit from ArgumentError). Each test asserts its
      # adapter's current behaviour.

      def test_unknown_action_option_symbol_raises
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions({event: :click, method: :submit, options: [:bogus_modifier]}) }
        end
        expected = ::Vident::ParseError
        error = assert_raises(expected) { klass.new }
        assert_match(/Invalid option|bogus_modifier/i, error.message)
      end

      def test_action_numeric_argument_raises
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions 42 }
        end
        expected = ::Vident::ParseError
        assert_raises(expected) { klass.new }
      end

      def test_action_four_args_raises
        klass = define_component(name: "ButtonComponent")
        expected = ::Vident::ParseError
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
