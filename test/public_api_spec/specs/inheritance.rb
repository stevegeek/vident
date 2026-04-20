# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: stimulus do DSL inheritance — a subclass's `stimulus do ... end`
    # block is merged with its parent's (subclass appends, values/classes/
    # outlets/params merge by key with subclass winning on key conflict).
    # Multiple `stimulus do` blocks on the same class also merge.
    module Inheritance
      # ---- multiple stimulus do blocks on same class --------------------

      def test_multiple_stimulus_blocks_merge_actions
        klass = define_component(name: "FooComponent") do
          stimulus { actions :one }
          stimulus { actions :two }
        end
        assert_includes render(klass.new),
          'data-action="foo-component#one foo-component#two"'
      end

      def test_multiple_stimulus_blocks_merge_values_by_key
        klass = define_component(name: "FooComponent") do
          stimulus { values a: "first" }
          stimulus { values b: "second" }
        end
        html = render(klass.new)
        assert_match(/a-value="first"/, html)
        assert_match(/b-value="second"/, html)
      end

      def test_multiple_stimulus_blocks_later_wins_on_key_conflict
        klass = define_component(name: "FooComponent") do
          stimulus { values label: "first" }
          stimulus { values label: "override" }
        end
        assert_includes render(klass.new),
          'data-foo-component-label-value="override"'
      end

      # ---- parent → subclass merge --------------------------------------

      def test_subclass_inherits_parent_actions
        parent = define_component(name: "BaseComponent") do
          stimulus { actions :click }
        end
        child = Class.new(parent)
        child.define_singleton_method(:name) { "ChildComponent" }
        child.class_eval do
          stimulus { actions :hover }
        end
        # Stub a view_template / call so rendering works
        if child.ancestors.include?(::Phlex::HTML)
          child.define_method(:view_template) { root_element }
        else
          child.define_method(:call) { root_element }
        end
        assert_includes render(child.new),
          'data-action="child-component#click child-component#hover"'
      end

      def test_subclass_inherits_parent_targets
        parent = define_component(name: "BaseComponent") do
          stimulus { targets :base }
        end
        child = Class.new(parent)
        child.define_singleton_method(:name) { "ChildComponent" }
        child.class_eval do
          stimulus { targets :child_thing }
        end
        if child.ancestors.include?(::Phlex::HTML)
          child.define_method(:view_template) { root_element }
        else
          child.define_method(:call) { root_element }
        end
        assert_includes render(child.new),
          'data-child-component-target="base childThing"'
      end

      def test_subclass_inherits_parent_classes_merges_by_key
        parent = define_component(name: "BaseComponent") do
          stimulus { classes loading: "opacity-50", base: "base-only" }
        end
        child = Class.new(parent)
        child.define_singleton_method(:name) { "ChildComponent" }
        child.class_eval do
          stimulus { classes loading: "animate-pulse", child_only: "child" }
        end
        if child.ancestors.include?(::Phlex::HTML)
          child.define_method(:view_template) { root_element }
        else
          child.define_method(:call) { root_element }
        end
        html = render(child.new)
        # subclass wins on conflict
        assert_includes html, 'data-child-component-loading-class="animate-pulse"'
        # parent-only retained
        assert_includes html, 'data-child-component-base-class="base-only"'
        # subclass-only retained
        assert_includes html, 'data-child-component-child-only-class="child"'
      end

      def test_parent_without_subclass_dsl_still_emits
        parent = define_component(name: "BaseComponent") do
          stimulus { actions :click }
        end
        child = Class.new(parent)
        child.define_singleton_method(:name) { "ChildComponent" }
        # No stimulus do in child
        if child.ancestors.include?(::Phlex::HTML)
          child.define_method(:view_template) { root_element }
        else
          child.define_method(:call) { root_element }
        end
        assert_includes render(child.new), 'data-action="child-component#click"'
      end

      # ---- grandparent → parent → child chain ---------------------------

      def test_three_level_inheritance_accumulates
        grand = define_component(name: "GrandComponent") do
          stimulus { actions :a }
        end
        parent = Class.new(grand)
        parent.define_singleton_method(:name) { "ParentComponent" }
        parent.class_eval { stimulus { actions :b } }

        child = Class.new(parent)
        child.define_singleton_method(:name) { "ChildComponent" }
        child.class_eval { stimulus { actions :c } }
        if child.ancestors.include?(::Phlex::HTML)
          child.define_method(:view_template) { root_element }
        else
          child.define_method(:call) { root_element }
        end
        assert_includes render(child.new),
          'data-action="child-component#a child-component#b child-component#c"'
      end
    end
  end
end
