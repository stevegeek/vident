# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: class_list_for_stimulus_classes — SSR helper that resolves
    # selected stimulus DSL class entries into an inlinable String. Also
    # locks the Tailwind-merge integration behaviour (active when
    # TailwindMerge::Merger is defined).
    module ClassList
      # ---- class_list_for_stimulus_classes -------------------------------

      def test_class_list_resolves_single_stimulus_class
        klass = define_component(name: "PanelComponent") do
          stimulus { classes loading: "opacity-50" }
        end
        assert_equal "opacity-50", klass.new.class_list_for_stimulus_classes(:loading)
      end

      def test_class_list_resolves_multiple_names_in_one_call
        klass = define_component(name: "PanelComponent") do
          stimulus { classes loading: "opacity-50", active: "bg-blue-500" }
        end
        result = klass.new.class_list_for_stimulus_classes(:loading, :active)
        # Order within stimulus_classes is insertion order
        assert_match(/opacity-50/, result)
        assert_match(/bg-blue-500/, result)
      end

      def test_class_list_returns_empty_string_when_no_matching_classes
        klass = define_component(name: "PanelComponent") do
          stimulus { classes loading: "opacity-50" }
        end
        assert_equal "", klass.new.class_list_for_stimulus_classes(:nonexistent)
      end

      def test_class_list_for_stimulus_classes_with_proc_resolution
        klass = define_component(name: "PanelComponent") do
          prop :status, Symbol, default: :ok
          stimulus do
            classes status: -> { (@status == :ok) ? "bg-green-500" : "bg-red-500" }
          end
        end
        assert_equal "bg-green-500",
          klass.new(status: :ok).class_list_for_stimulus_classes(:status)
        assert_equal "bg-red-500",
          klass.new(status: :error).class_list_for_stimulus_classes(:status)
      end

      def test_class_list_excludes_unnamed_stimulus_classes
        # If user passes :loading but not :active, only :loading's CSS should
        # appear in the SSR class list.
        klass = define_component(name: "PanelComponent") do
          stimulus { classes loading: "opacity-50", active: "bg-blue-500" }
        end
        result = klass.new.class_list_for_stimulus_classes(:loading)
        assert_match(/opacity-50/, result)
        refute_match(/bg-blue-500/, result)
      end

      def test_class_list_with_no_classes_declared_returns_empty_string
        klass = define_component(name: "PanelComponent")
        assert_equal "", klass.new.class_list_for_stimulus_classes(:loading)
      end

      # ---- Tailwind merger ----------------------------------------------

      def test_tailwind_merger_available_when_gem_loaded
        # The dummy app loads tailwind_merge via Gemfile. If the gem is
        # absent in a future build config, this predicate flips.
        skip "Tailwind merger not loaded" unless defined?(::TailwindMerge::Merger)
        klass = define_component(name: "PanelComponent")
        assert klass.new.send(:tailwind_merge_available?)
        refute_nil klass.new.tailwind_merger
      end

      def test_tailwind_merger_is_thread_local_singleton
        skip "Tailwind merger not loaded" unless defined?(::TailwindMerge::Merger)
        klass = define_component(name: "PanelComponent")
        a = klass.new.tailwind_merger
        b = klass.new.tailwind_merger
        assert_same a, b
      end

      # ---- class-list precedence when rendered (overlap with root_element) -

      def test_classes_prop_appends_after_html_options_class
        # SPEC-NOTE: use class names that don't collide with Tailwind
        # utilities, or the TailwindMerger dedup will eat one of them.
        # `from-*` looks like a gradient utility to the merger; `alpha` /
        # `beta` don't.
        klass = define_component(name: "PanelComponent")
        html = render(klass.new(html_options: {class: "alpha"}, classes: "beta"))
        assert_match(/class="panel-component alpha beta"/, html)
      end

      def test_tailwind_merger_resolves_conflicting_classes
        # Locks the TailwindMerger integration: conflicting utilities
        # (last-wins per Tailwind semantics) collapse rather than duplicate.
        skip "Tailwind merger not loaded" unless defined?(::TailwindMerge::Merger)
        klass = define_component(name: "PanelComponent")
        # p-2 and p-4 conflict on padding — merger keeps the later one.
        html = render(klass.new(html_options: {class: "p-2"}, classes: "p-4"))
        assert_match(/class="panel-component p-4"/, html)
        refute_match(/p-2/, html)
      end
    end
  end
end
