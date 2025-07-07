# frozen_string_literal: true

require "test_helper"

class StimulusBuilderTest < ActiveSupport::TestCase
  def setup
    @builder = Vident::StimulusDSL::StimulusBuilder.new
  end

  def test_initial_state
    assert_equal [], @builder.instance_variable_get(:@actions)
    assert_equal [], @builder.instance_variable_get(:@targets)
    assert_equal({}, @builder.instance_variable_get(:@values))
    assert_equal({}, @builder.instance_variable_get(:@classes))
    assert_equal({}, @builder.instance_variable_get(:@outlets))
  end

  def test_actions_with_symbols
    @builder.actions(:click, :submit, :toggle)
    assert_equal [:click, :submit, :toggle], @builder.instance_variable_get(:@actions)
  end

  def test_actions_with_strings
    @builder.actions("click", "submit", "toggle")
    assert_equal ["click", "submit", "toggle"], @builder.instance_variable_get(:@actions)
  end

  def test_actions_with_mixed_types
    @builder.actions(:click, "submit", :toggle)
    assert_equal [:click, "submit", :toggle], @builder.instance_variable_get(:@actions)
  end

  def test_actions_called_multiple_times
    @builder.actions(:click, :submit)
    @builder.actions(:toggle, :focus)
    assert_equal [:click, :submit, :toggle, :focus], @builder.instance_variable_get(:@actions)
  end

  def test_actions_with_no_arguments
    @builder.actions
    assert_equal [], @builder.instance_variable_get(:@actions)
  end

  def test_targets_with_symbols
    @builder.targets(:button, :form, :input)
    assert_equal [:button, :form, :input], @builder.instance_variable_get(:@targets)
  end

  def test_targets_with_strings
    @builder.targets("button", "form", "input")
    assert_equal ["button", "form", "input"], @builder.instance_variable_get(:@targets)
  end

  def test_targets_called_multiple_times
    @builder.targets(:button, :form)
    @builder.targets(:input, :textarea)
    assert_equal [:button, :form, :input, :textarea], @builder.instance_variable_get(:@targets)
  end

  def test_targets_with_no_arguments
    @builder.targets
    assert_equal [], @builder.instance_variable_get(:@targets)
  end

  def test_values_from_props_with_symbols
    @builder.values_from_props(:name, :count, :active)
    expected = [:name, :count, :active]
    assert_equal expected, @builder.instance_variable_get(:@values_from_props)
  end

  def test_values_with_hash
    @builder.values(name: "default", count: 0, active: true)
    expected = { name: "default", count: 0, active: true }
    assert_equal expected, @builder.instance_variable_get(:@values)
  end

  def test_values_with_mixed_static_and_from_props
    @builder.values_from_props(:auto_mapped, :another_auto_mapped)
    @builder.values(explicit: "value")
    
    assert_equal([:auto_mapped, :another_auto_mapped], @builder.instance_variable_get(:@values_from_props))
    assert_equal({ explicit: "value" }, @builder.instance_variable_get(:@values))
  end

  def test_values_hash_overwrites_existing_keys
    @builder.values(name: "first")
    @builder.values(name: "second", count: 1)
    
    expected = { name: "second", count: 1 }
    assert_equal expected, @builder.instance_variable_get(:@values)
  end

  def test_values_with_no_arguments
    @builder.values
    assert_equal({}, @builder.instance_variable_get(:@values))
  end

  def test_classes_with_hash
    @builder.classes(loading: "opacity-50", active: "bg-blue-500")
    expected = { loading: "opacity-50", active: "bg-blue-500" }
    assert_equal expected, @builder.instance_variable_get(:@classes)
  end

  def test_classes_called_multiple_times
    @builder.classes(loading: "opacity-50")
    @builder.classes(active: "bg-blue-500", disabled: "cursor-not-allowed")
    
    expected = { loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed" }
    assert_equal expected, @builder.instance_variable_get(:@classes)
  end

  def test_classes_overwrites_existing_keys
    @builder.classes(loading: "first-class")
    @builder.classes(loading: "second-class")
    
    expected = { loading: "second-class" }
    assert_equal expected, @builder.instance_variable_get(:@classes)
  end

  def test_classes_with_string_values
    @builder.classes(loading: "opacity-50 cursor-wait", error: "text-red-500 border-red-500")
    expected = { loading: "opacity-50 cursor-wait", error: "text-red-500 border-red-500" }
    assert_equal expected, @builder.instance_variable_get(:@classes)
  end

  def test_classes_with_array_values
    @builder.classes(loading: ["opacity-50", "cursor-wait"], error: ["text-red-500", "border-red-500"])
    expected = { loading: ["opacity-50", "cursor-wait"], error: ["text-red-500", "border-red-500"] }
    assert_equal expected, @builder.instance_variable_get(:@classes)
  end

  def test_outlets_with_hash
    @builder.outlets(modal: ".modal", tooltip: ".tooltip")
    expected = { modal: ".modal", tooltip: ".tooltip" }
    assert_equal expected, @builder.instance_variable_get(:@outlets)
  end

  def test_outlets_called_multiple_times
    @builder.outlets(modal: ".modal")
    @builder.outlets(tooltip: ".tooltip", dropdown: ".dropdown")
    
    expected = { modal: ".modal", tooltip: ".tooltip", dropdown: ".dropdown" }
    assert_equal expected, @builder.instance_variable_get(:@outlets)
  end

  def test_outlets_with_second_call_overwrites_key
    @builder.outlets(modal: ".first-modal")
    @builder.outlets(modal: ".second-modal")
    
    expected = { modal: ".second-modal" }
    assert_equal expected, @builder.instance_variable_get(:@outlets)
  end

  def test_outlets_with_component_selector_patterns
    @builder.outlets(
      user_profile: "[data-controller='user-profile']",
      notification: "#notification-area",
      sidebar: ".sidebar-container"
    )
    
    expected = {
      user_profile: "[data-controller='user-profile']",
      notification: "#notification-area",
      sidebar: ".sidebar-container"
    }
    assert_equal expected, @builder.instance_variable_get(:@outlets)
  end

  def test_all_methods_chained
    result = @builder
      .actions(:click, :submit)
      .targets(:button, :form)
      .values_from_props(:name, :count)
      .classes(loading: "opacity-50")
      .outlets(modal: ".modal")
    
    assert_equal @builder, result
    assert_equal [:click, :submit], @builder.instance_variable_get(:@actions)
    assert_equal [:button, :form], @builder.instance_variable_get(:@targets)
    assert_equal([:name, :count], @builder.instance_variable_get(:@values_from_props))
    assert_equal({ loading: "opacity-50" }, @builder.instance_variable_get(:@classes))
    assert_equal({ modal: ".modal" }, @builder.instance_variable_get(:@outlets))
  end

  def test_to_attributes_method_returns_complete_attributes
    @builder
      .actions(:click, :submit)
      .targets(:button, :form)
      .values(name: "test", count: :auto_map_from_prop)
      .classes(loading: "opacity-50", active: "bg-blue-500")
      .outlets(modal: ".modal")
    
    result = @builder.to_attributes
    
    expected = {
      stimulus_actions: [:click, :submit],
      stimulus_targets: [:button, :form],
      stimulus_values: { name: "test", count: :auto_map_from_prop },
      stimulus_classes: { loading: "opacity-50", active: "bg-blue-500" },
      stimulus_outlets: { modal: ".modal" }
    }
    
    assert_equal expected, result
  end

  def test_to_attributes_method_with_empty_builder
    result = @builder.to_attributes
    
    # Empty builder returns empty hash since all collections are empty
    expected = {}
    
    assert_equal expected, result
  end

  def test_to_attributes_method_filters_empty_collections
    @builder.actions(:click)
    # Leave targets, values, classes, outlets empty
    
    result = @builder.to_attributes
    
    # Only non-empty collections are included
    expected = {
      stimulus_actions: [:click]
    }
    
    assert_equal expected, result
  end

  def test_builder_accumulates_values
    @builder.actions(:click)
    first_result = @builder.to_attributes
    
    @builder.actions(:submit)
    second_result = @builder.to_attributes
    
    # Builder accumulates actions across calls - first_result reflects current state when called
    # Since to_attributes returns current state, both results will be the same as the builder accumulates
    assert_equal [:click], first_result[:stimulus_actions]
    assert_equal [:click, :submit], second_result[:stimulus_actions]
    
    # Verify first result was captured correctly at that point in time
    fresh_builder = Vident::StimulusDSL::StimulusBuilder.new
    fresh_builder.actions(:click)
    fresh_result = fresh_builder.to_attributes
    assert_equal [:click], fresh_result[:stimulus_actions]
  end

  def test_complex_realistic_example
    @builder
      .actions(:click, :mouseenter, :mouseleave, :focus, :blur)
      .targets(:button, :icon, :tooltip, :spinner)
      .values(
        url: :auto_map_from_prop,
        method: "POST",
        confirm: :auto_map_from_prop,
        loading: false,
        disabled: :auto_map_from_prop
      )
      .classes(
        loading: "opacity-50 cursor-wait",
        disabled: "opacity-25 cursor-not-allowed",
        success: "bg-green-500 text-white",
        error: "bg-red-500 text-white"
      )
      .outlets(
        notification: "[data-controller='notification']",
        modal: ".modal-container"
      )
    
    result = @builder.to_attributes
    
    assert_equal [:click, :mouseenter, :mouseleave, :focus, :blur], result[:stimulus_actions]
    assert_equal [:button, :icon, :tooltip, :spinner], result[:stimulus_targets]
    
    expected_values = {
      url: :auto_map_from_prop,
      method: "POST",
      confirm: :auto_map_from_prop,
      loading: false,
      disabled: :auto_map_from_prop
    }
    assert_equal expected_values, result[:stimulus_values]
    
    expected_classes = {
      loading: "opacity-50 cursor-wait",
      disabled: "opacity-25 cursor-not-allowed",
      success: "bg-green-500 text-white",
      error: "bg-red-500 text-white"
    }
    assert_equal expected_classes, result[:stimulus_classes]
    
    expected_outlets = {
      notification: "[data-controller='notification']",
      modal: ".modal-container"
    }
    assert_equal expected_outlets, result[:stimulus_outlets]
  end
end