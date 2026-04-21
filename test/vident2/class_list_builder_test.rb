# frozen_string_literal: true

require "test_helper"
require "vident2"

module Vident2
  class ClassListBuilderTest < Minitest::Test
    CLB = ::Vident2::Internals::ClassListBuilder

    # ---- component_name tier (always first) ----------------------------

    def test_component_name_appears_first
      assert_equal "foo-component",
        CLB.call(component_name: "foo-component")
    end

    def test_returns_nil_when_no_classes_at_all
      assert_nil CLB.call
    end

    # ---- priority cascade: only one of the middle 4 wins ---------------

    def test_root_element_classes_appears_when_nothing_higher
      result = CLB.call(component_name: "foo", root_element_classes: "extra")
      assert_equal "foo extra", result
    end

    def test_root_element_attributes_classes_wins_over_root_element_classes
      result = CLB.call(
        component_name: "foo",
        root_element_classes: "lower",
        root_element_attributes_classes: "higher"
      )
      assert_equal "foo higher", result
      refute_match(/lower/, result)
    end

    def test_root_element_html_class_wins_over_attributes_classes
      result = CLB.call(
        component_name: "foo",
        root_element_classes: "a",
        root_element_attributes_classes: "b",
        root_element_html_class: "c"
      )
      assert_equal "foo c", result
    end

    def test_html_options_class_is_highest_cascade_tier
      result = CLB.call(
        component_name: "foo",
        root_element_classes: "a",
        root_element_attributes_classes: "b",
        root_element_html_class: "c",
        html_options_class: "d"
      )
      assert_equal "foo d", result
    end

    # ---- classes_prop always appended ----------------------------------

    def test_classes_prop_appends_after_cascade_winner
      result = CLB.call(
        component_name: "foo",
        html_options_class: "winner",
        classes_prop: "always"
      )
      assert_equal "foo winner always", result
    end

    def test_classes_prop_appends_with_no_cascade_contributor
      result = CLB.call(component_name: "foo", classes_prop: "extra")
      assert_equal "foo extra", result
    end

    # ---- Array input normalisation -------------------------------------

    def test_classes_prop_array_is_flattened
      result = CLB.call(component_name: "foo", classes_prop: ["a", "b", "c"])
      assert_equal "foo a b c", result
    end

    def test_strings_with_spaces_are_split
      result = CLB.call(component_name: "foo", classes_prop: "a b c")
      assert_equal "foo a b c", result
    end

    def test_duplicate_classes_are_removed_order_preserving
      result = CLB.call(component_name: "foo", classes_prop: "foo bar foo baz")
      assert_equal "foo bar baz", result
    end

    # ---- Tailwind merge path -------------------------------------------

    def test_tailwind_merger_is_invoked_when_provided
      merger = Object.new
      merger.define_singleton_method(:merge) { |s| "merged(#{s})" }
      result = CLB.call(component_name: "foo", classes_prop: "p-2 p-4", tailwind_merger: merger)
      assert_equal "merged(foo p-2 p-4)", result
    end

    def test_no_tailwind_merger_means_plain_joined_string
      result = CLB.call(component_name: "foo", classes_prop: "p-2 p-4")
      assert_equal "foo p-2 p-4", result
    end

    # ---- stimulus_class_names filter -----------------------------------

    def make_class_map(name, css)
      ::Vident2::Stimulus::ClassMap.new(
        controller: ::Vident2::Stimulus::Controller.new(path: "x", name: "x"),
        name: name,
        css: css
      )
    end

    def test_stimulus_class_names_filter_selects_matching_entries
      maps = [make_class_map("loading", "opacity-50"), make_class_map("active", "bg-blue")]
      result = CLB.call(stimulus_classes: maps, stimulus_class_names: [:loading])
      assert_equal "opacity-50", result
    end

    def test_stimulus_class_names_filter_excludes_unnamed
      maps = [make_class_map("loading", "opacity-50"), make_class_map("active", "bg-blue")]
      result = CLB.call(stimulus_classes: maps, stimulus_class_names: [:loading])
      refute_match(/bg-blue/, result)
    end

    def test_stimulus_class_names_dasherizes_input_for_match
      maps = [make_class_map("submit-button", "btn-primary")]
      result = CLB.call(stimulus_classes: maps, stimulus_class_names: [:submit_button])
      assert_equal "btn-primary", result
    end

    def test_empty_stimulus_class_names_returns_nil
      maps = [make_class_map("loading", "opacity-50")]
      assert_nil CLB.call(stimulus_classes: maps, stimulus_class_names: [])
    end
  end
end
