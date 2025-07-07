# frozen_string_literal: true

require "test_helper"

class StimulusDSLEdgeCasesTest < ActiveSupport::TestCase
  # Test component class for edge cases
  class EdgeCaseComponent
    include Vident::Component
    
    def initialize(**props)
      props.each { |key, value| instance_variable_set("@#{key}", value) }
    end
  end

  def setup
    @component_class = Class.new(EdgeCaseComponent)
  end

  def test_nil_values_in_dsl
    @component_class.stimulus do
      values explicit_nil: nil, empty_string: "", zero: 0, false_value: false
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { explicit_nil: nil, empty_string: "", zero: 0, false_value: false }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_complex_data_types_in_values
    @component_class.stimulus do
      values(
        array: [1, 2, 3],
        hash: { nested: "value" },
        numeric: 42,
        float: 3.14,
        string: "test"
      )
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = {
      array: [1, 2, 3],
      hash: { nested: "value" },
      numeric: 42,
      float: 3.14,
      string: "test"
    }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_edge_case_class_names
    @component_class.stimulus do
      classes(
        "kebab-case": "valid-class",
        snake_case: "valid-class",
        camelCase: "valid-class",
        "with spaces": "invalid but allowed",
        "with-special!@#": "edge-case"
      )
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = {
      "kebab-case": "valid-class",
      snake_case: "valid-class",
      camelCase: "valid-class",
      "with spaces": "invalid but allowed",
      "with-special!@#": "edge-case"
    }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_very_long_attribute_names
    long_name = "a" * 100
    @component_class.stimulus do
      actions long_name.to_sym
      targets long_name.to_sym
      values long_name.to_sym => "value"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_includes dsl_attrs[:stimulus_actions], long_name.to_sym
    assert_includes dsl_attrs[:stimulus_targets], long_name.to_sym
    assert_equal({ long_name.to_sym => "value" }, dsl_attrs[:stimulus_values])
  end

  def test_unicode_characters_in_names
    @component_class.stimulus do
      actions :ação, :事件, :действие
      targets :elemento, :要素, :элемент
      values título: "título", 名前: "名前", имя: "имя"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal [:ação, :事件, :действие], dsl_attrs[:stimulus_actions]
    assert_equal [:elemento, :要素, :элемент], dsl_attrs[:stimulus_targets]
    expected_values = { título: "título", 名前: "名前", имя: "имя" }
    assert_equal expected_values, dsl_attrs[:stimulus_values]
  end

  def test_numeric_keys_in_hash
    @component_class.stimulus do
      values 1 => "one", 2 => "two", 3.5 => "three-point-five"
      classes 0 => "zero-class", 999 => "large-number"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected_values = { 1 => "one", 2 => "two", 3.5 => "three-point-five" }
    expected_classes = { 0 => "zero-class", 999 => "large-number" }
    assert_equal expected_values, dsl_attrs[:stimulus_values]
    assert_equal expected_classes, dsl_attrs[:stimulus_classes]
  end

  def test_empty_and_whitespace_strings
    @component_class.stimulus do
      actions "", "   ", "\t", "\n"
      targets "", " spaces ", "\ttab\t"
      values empty: "", whitespace: "   ", tab: "\t", newline: "\n"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal ["", "   ", "\t", "\n"], dsl_attrs[:stimulus_actions]
    assert_equal ["", " spaces ", "\ttab\t"], dsl_attrs[:stimulus_targets]
    expected_values = { empty: "", whitespace: "   ", tab: "\t", newline: "\n" }
    assert_equal expected_values, dsl_attrs[:stimulus_values]
  end

  def test_deeply_nested_hash_values
    deeply_nested = {
      level1: {
        level2: {
          level3: {
            level4: "deep value"
          }
        }
      }
    }
    
    @component_class.stimulus do
      values nested: deeply_nested
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal({ nested: deeply_nested }, dsl_attrs[:stimulus_values])
  end

  def test_circular_reference_handling
    circular_hash = { self: nil }
    circular_hash[:self] = circular_hash
    
    @component_class.stimulus do
      values circular: circular_hash
    end
    
    # Should not raise an infinite recursion error
    assert_nothing_raised do
      dsl_attrs = @component_class.stimulus_dsl_attributes
      assert_equal({ circular: circular_hash }, dsl_attrs[:stimulus_values])
    end
  end

  def test_proc_and_lambda_values
    test_proc = proc { "proc value" }
    test_lambda = lambda { "lambda value" }
    
    @component_class.stimulus do
      values proc_value: test_proc, lambda_value: test_lambda
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { proc_value: test_proc, lambda_value: test_lambda }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_class_and_module_as_values
    @component_class.stimulus do
      values class_value: String, module_value: Enumerable
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { class_value: String, module_value: Enumerable }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_extremely_large_arrays
    large_array = (1..1000).to_a
    @component_class.stimulus do
      actions(*large_array.map(&:to_s))
      targets(*large_array.map { |i| "target_#{i}" })
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal large_array.map(&:to_s), dsl_attrs[:stimulus_actions]
    assert_equal large_array.map { |i| "target_#{i}" }, dsl_attrs[:stimulus_targets]
  end

  def test_mixed_argument_types_in_same_call
    @component_class.stimulus do
      actions :symbol, "string", 123, nil, true, false
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = [:symbol, "string", 123, nil, true, false]
    assert_equal expected, dsl_attrs[:stimulus_actions]
  end

  def test_inheritance_with_conflicting_dsl_attributes
    parent_class = Class.new(EdgeCaseComponent) do
      stimulus do
        actions :parent_action
        values parent_value: "parent", shared: "from_parent"
      end
    end
    
    child_class = Class.new(parent_class) do
      stimulus do
        actions :child_action
        values child_value: "child", shared: "from_child"
      end
    end
    
    child_attrs = child_class.stimulus_dsl_attributes
    assert_equal [:parent_action, :child_action], child_attrs[:stimulus_actions]
    
    # Child values should override parent values for same keys
    expected_values = {
      parent_value: "parent",
      shared: "from_child",  # Child overrides parent
      child_value: "child"
    }
    assert_equal expected_values, child_attrs[:stimulus_values]
  end

  def test_auto_map_with_non_existent_instance_variables
    component = @component_class.new
    
    @component_class.stimulus do
      values existing_prop: :auto_map_from_prop, non_existent: :auto_map_from_prop
    end
    
    # Set only one instance variable
    component.instance_variable_set(:@existing_prop, "exists")
    
    resolved = component.send(:resolve_stimulus_dsl_values, @component_class.stimulus_dsl_attributes[:stimulus_values])
    
    expected = {
      existing_prop: "exists"
      # non_existent should not be included since the instance variable doesn't exist
    }
    assert_equal expected, resolved
  end

  def test_auto_map_with_complex_instance_variable_values
    component = @component_class.new
    
    # Set complex instance variables
    component.instance_variable_set(:@array_prop, [1, 2, 3])
    component.instance_variable_set(:@hash_prop, { key: "value" })
    component.instance_variable_set(:@object_prop, Time.now)
    
    @component_class.stimulus do
      values array_prop: :auto_map_from_prop, hash_prop: :auto_map_from_prop, object_prop: :auto_map_from_prop
    end
    
    resolved = component.send(:resolve_stimulus_dsl_values, @component_class.stimulus_dsl_attributes[:stimulus_values])
    
    assert_equal [1, 2, 3], resolved[:array_prop]
    assert_equal({ key: "value" }, resolved[:hash_prop])
    assert_instance_of Time, resolved[:object_prop]
  end

  def test_stimulus_block_called_at_runtime_vs_class_definition
    # Test that stimulus blocks work when called after class is defined
    @component_class.stimulus do
      actions :runtime_action
    end
    
    # Add more attributes at runtime
    @component_class.stimulus do
      targets :runtime_target
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_includes dsl_attrs[:stimulus_actions], :runtime_action
    assert_includes dsl_attrs[:stimulus_targets], :runtime_target
  end

  def test_thread_safety_with_concurrent_dsl_calls
    # Test that concurrent modifications don't interfere with each other
    threads = []
    results = []
    
    10.times do |i|
      threads << Thread.new do
        component_class = Class.new(EdgeCaseComponent)
        component_class.stimulus do
          actions "action_#{i}".to_sym
          values "value_#{i}".to_sym => i
        end
        results[i] = component_class.stimulus_dsl_attributes
      end
    end
    
    threads.each(&:join)
    
    # Each class should have its own independent attributes
    10.times do |i|
      assert_includes results[i][:stimulus_actions], "action_#{i}".to_sym
      assert_equal({ "value_#{i}".to_sym => i }, results[i][:stimulus_values])
    end
  end

  def test_dsl_with_invalid_method_calls
    # Test that invalid method calls inside stimulus block don't break everything
    assert_nothing_raised do
      @component_class.stimulus do
        actions :valid_action
        # This would be an invalid call but shouldn't break the DSL
        begin
          non_existent_method(:invalid)
        rescue NoMethodError
          # Expected - just continue
        end
        targets :valid_target
      end
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_includes dsl_attrs[:stimulus_actions], :valid_action
    assert_includes dsl_attrs[:stimulus_targets], :valid_target
  end

  def test_dsl_with_exception_in_block
    # Test that exceptions in stimulus blocks are handled gracefully
    assert_raises(StandardError) do
      @component_class.stimulus do
        actions :before_error
        raise StandardError, "Test error"
        actions :after_error  # This won't be reached
      end
    end
    
    # The attributes set before the error should still be there
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_includes dsl_attrs[:stimulus_actions], :before_error
    refute_includes dsl_attrs[:stimulus_actions], :after_error
  end

  def test_memory_usage_with_large_dsl_definitions
    # Test that large DSL definitions don't cause memory issues
    large_component_class = Class.new(EdgeCaseComponent)
    
    # Add many attributes
    large_component_class.stimulus do
      actions(*(1..500).map { |i| "action_#{i}".to_sym })
      targets(*(1..500).map { |i| "target_#{i}".to_sym })
      values((1..500).map { |i| ["value_#{i}".to_sym, "value_#{i}"] }.to_h)
      classes(**((1..500).map { |i| ["class_#{i}".to_sym, "class_#{i}"] }.to_h))
    end
    
    dsl_attrs = large_component_class.stimulus_dsl_attributes
    
    assert_equal 500, dsl_attrs[:stimulus_actions].length
    assert_equal 500, dsl_attrs[:stimulus_targets].length
    assert_equal 500, dsl_attrs[:stimulus_values].length
    assert_equal 500, dsl_attrs[:stimulus_classes].length
  end
end