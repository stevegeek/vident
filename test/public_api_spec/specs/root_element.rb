# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: root_element rendering, element_tag selection, block-form
    # (yields component), `root` alias, html_options merging, class-list
    # precedence (6-tier ladder per SKILL.md §4 — a regression magnet),
    # root_element_attributes Hash keys, id: prop behaviour.
    module RootElement
      # ---- basic render --------------------------------------------------

      def test_root_element_renders_div_by_default
        klass = define_component(name: "FooComponent")
        html = render(klass.new)
        assert_match(/<div\b/, html)
        assert_match(/<\/div>/, html)
      end

      def test_root_element_has_id_attribute
        klass = define_component(name: "FooComponent")
        assert_match(/id="foo-component-[a-f0-9]+"/, render(klass.new))
      end

      def test_explicit_id_overrides_auto_generated
        klass = define_component(name: "FooComponent")
        assert_match(/id="my-foo"/, render(klass.new(id: "my-foo")))
      end

      # ---- element_tag ---------------------------------------------------

      def test_element_tag_prop_sets_root_tag
        klass = define_component(name: "ButtonComponent")
        html = render(klass.new(element_tag: :button))
        assert_match(/<button\b/, html)
        assert_match(/<\/button>/, html)
      end

      def test_element_tag_in_root_element_attributes
        klass = define_component(name: "LinkComponent") do
          define_method(:root_element_attributes) { {element_tag: :a} }
        end
        assert_match(/<a\b/, render(klass.new))
      end

      # SPEC-NOTE: component.rb:77 has `@element_tag.presence&.to_sym || :div`
      # as a blank-fallback, but the `element_tag` prop is typed `Symbol` in
      # Literal, so `""` is rejected at prop assignment before the fallback
      # can run. The fallback is only reachable if @element_tag is set to
      # `:""` directly. Not testing here — unreachable from user code via
      # the prop.

      # ---- `root` alias --------------------------------------------------

      def test_root_is_alias_for_root_element
        # The `root` instance method is a simple alias forwarding to
        # root_element (component.rb:73). Branch on adapter so we only
        # redefine the right render entry point for each.
        klass = define_component(name: "FooComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) { root }
          else
            define_method(:call) { root }
          end
        end
        assert_match(/<div[^>]*data-controller="foo-component"/, render(klass.new))
      end

      # ---- block form ---------------------------------------------------

      def test_root_element_with_block_wraps_content
        klass = define_component(name: "FooComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) { root_element { plain "hello" } }
          else
            define_method(:call) { root_element { "hello" } }
          end
        end
        assert_match(/<div[^>]*>hello<\/div>/, render(klass.new))
      end

      # ---- class-list precedence (6-tier ladder) -------------------------

      def test_component_name_is_first_class_on_root
        klass = define_component(name: "FooComponent")
        assert_match(/class="foo-component"/, render(klass.new))
      end

      def test_root_element_classes_appended_when_nothing_higher
        klass = define_component(name: "FooComponent") do
          define_method(:root_element_classes) { "extra-class" }
        end
        assert_match(/class="[^"]*foo-component[^"]*extra-class[^"]*"/, render(klass.new))
      end

      def test_root_element_attributes_classes_wins_over_root_element_classes
        # SPEC-NOTE (G17-G19 precedence): the middle 4 tiers are a
        # **priority cascade** (only the highest-priority non-nil wins),
        # not an append chain. component_name stays first, `classes:` prop
        # always appends at the end, but in between only ONE of
        # {root_element_classes, root_element_attributes[:classes],
        #  root_element(class:), html_options[:class]} actually contributes.
        klass = define_component(name: "FooComponent") do
          define_method(:root_element_classes) { "lower-priority" }
          define_method(:root_element_attributes) { {classes: "higher-priority"} }
        end
        html = render(klass.new)
        assert_match(/class="foo-component higher-priority"/, html)
        refute_match(/lower-priority/, html)
      end

      def test_html_options_class_wins_over_root_element_classes
        klass = define_component(name: "FooComponent") do
          define_method(:root_element_classes) { "overridden" }
        end
        html = render(klass.new(html_options: {class: "winner"}))
        assert_match(/class="foo-component winner"/, html)
        refute_match(/overridden/, html)
      end

      def test_classes_prop_always_appended_even_over_html_options_class
        # SPEC-NOTE (G18): `classes:` prop is ALWAYS appended. This is the
        # "always wins" rule that's easy to regress.
        klass = define_component(name: "FooComponent")
        html = render(klass.new(html_options: {class: "winner"}, classes: "always-there"))
        assert_match(/class="foo-component winner always-there"/, html)
      end

      def test_classes_prop_with_no_other_classes_appends_after_component_name
        klass = define_component(name: "FooComponent")
        html = render(klass.new(classes: "extra"))
        assert_match(/class="foo-component extra"/, html)
      end

      # ---- html_options merging -----------------------------------------

      def test_html_options_prop_appears_on_root
        klass = define_component(name: "FooComponent")
        html = render(klass.new(html_options: {title: "hi"}))
        assert_match(/title="hi"/, html)
      end

      def test_root_element_attributes_html_options_merges_with_prop
        # component_attribute_resolver.rb:18 merges prop onto
        # root_element_attributes[:html_options] with prop winning.
        klass = define_component(name: "FooComponent") do
          define_method(:root_element_attributes) { {html_options: {title: "from-attrs", role: "presentation"}} }
        end
        html = render(klass.new(html_options: {title: "from-prop"}))
        # Prop wins on :title conflict
        assert_match(/title="from-prop"/, html)
        # Non-conflicting key from attrs still appears
        assert_match(/role="presentation"/, html)
      end

      # ---- root_element_attributes defaults ------------------------------

      def test_not_overriding_root_element_attributes_is_same_as_empty_hash
        klass_not_overridden = define_component(name: "FooComponent")
        klass_empty_override = define_component(name: "FooComponent") do
          define_method(:root_element_attributes) { {} }
        end
        # Same class name → same data-controller; primary proof they render
        # compatibly is class="foo-component" on both
        a = render(klass_not_overridden.new)
        b = render(klass_empty_override.new)
        assert_match(/class="foo-component"/, a)
        assert_match(/class="foo-component"/, b)
      end
    end
  end
end
