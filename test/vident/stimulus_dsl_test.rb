# frozen_string_literal: true

require "test_helper"

class StimulusDSLTest < ActiveSupport::TestCase

  def setup
    # Create a fresh component class for each test to avoid state sharing
    @component_class = Class.new do
      include Vident::StimulusDSL
      
      def initialize(**props)
        props.each { |key, value| instance_variable_set("@#{key}", value) }
        @test_prop = "test_value"
        @another_prop = 42
      end
      
      def instance_variable_get(name)
        super(name)
      end
      
      def instance_variable_defined?(name)
        super(name)
      end
    end
    @component = @component_class.new
  end

  def test_stimulus_dsl_module_included
    assert @component_class.respond_to?(:stimulus)
    assert @component_class.respond_to?(:stimulus_dsl_attributes)
  end

  def test_stimulus_dsl_attributes_initially_empty
    # Fresh class should have empty DSL attributes
    fresh_class = Class.new { include Vident::StimulusDSL }
    dsl_attrs = fresh_class.stimulus_dsl_attributes
    
    assert_equal({}, dsl_attrs)
  end

  def test_stimulus_block_with_actions
    @component_class.stimulus do
      actions :click, :submit, :toggle
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal [:click, :submit, :toggle], dsl_attrs[:stimulus_actions]
  end

  def test_stimulus_block_with_targets
    @component_class.stimulus do
      targets :button, :form, :input
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal [:button, :form, :input], dsl_attrs[:stimulus_targets]
  end

  def test_stimulus_block_with_values_array
    @component_class.stimulus do
      values :name, :count, :active
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { name: :auto_map_from_prop, count: :auto_map_from_prop, active: :auto_map_from_prop }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_stimulus_block_with_values_hash
    @component_class.stimulus do
      values name: "default", count: 0, active: true
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { name: "default", count: 0, active: true }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_stimulus_block_with_classes_hash
    @component_class.stimulus do
      classes loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed" }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_stimulus_block_with_outlets
    @component_class.stimulus do
      outlets modal: ".modal", tooltip: ".tooltip"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { modal: ".modal", tooltip: ".tooltip" }
    assert_equal expected, dsl_attrs[:stimulus_outlets]
  end

  def test_stimulus_block_with_mixed_attributes
    @component_class.stimulus do
      actions :click, :submit
      targets :button, :form
      values :name, :count
      classes loading: "opacity-50", active: "bg-blue-500"
      outlets modal: ".modal"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    
    assert_equal [:click, :submit], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :form], dsl_attrs[:stimulus_targets]
    assert_equal({ name: :auto_map_from_prop, count: :auto_map_from_prop }, dsl_attrs[:stimulus_values])
    assert_equal({ loading: "opacity-50", active: "bg-blue-500" }, dsl_attrs[:stimulus_classes])
    assert_equal({ modal: ".modal" }, dsl_attrs[:stimulus_outlets])
  end

  def test_multiple_stimulus_blocks_merge
    @component_class.stimulus do
      actions :click
      targets :button
    end
    
    @component_class.stimulus do
      actions :submit
      targets :form
      values :name
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    
    assert_equal [:click, :submit], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :form], dsl_attrs[:stimulus_targets]
    assert_equal({ name: :auto_map_from_prop }, dsl_attrs[:stimulus_values])
  end

  def test_stimulus_block_inheritance
    parent_class = Class.new do
      include Vident::StimulusDSL
      stimulus do
        actions :click
        targets :button
      end
    end
    
    child_class = Class.new(parent_class) do
      stimulus do
        actions :submit
        targets :form
      end
    end
    
    parent_attrs = parent_class.stimulus_dsl_attributes
    child_attrs = child_class.stimulus_dsl_attributes
    
    # Parent should only have its own attributes
    assert_equal [:click], parent_attrs[:stimulus_actions]
    assert_equal [:button], parent_attrs[:stimulus_targets]
    
    # Child should have both parent and child attributes
    assert_equal [:click, :submit], child_attrs[:stimulus_actions]
    assert_equal [:button, :form], child_attrs[:stimulus_targets]
  end

  def test_empty_stimulus_block
    @component_class.stimulus do
      # Empty block should not cause errors
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    # Empty block should return empty hash since no attributes are set
    assert_equal({}, dsl_attrs)
  end

  def test_stimulus_block_with_no_arguments
    @component_class.stimulus do
      actions
      targets
      values
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    # When called with no arguments, methods should not add any attributes
    assert_equal({}, dsl_attrs)
  end

  def test_stimulus_block_with_duplicate_values
    @component_class.stimulus do
      actions :click, :click, :submit
      targets :button, :button, :form
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    # Should preserve duplicates (the underlying system handles deduplication)
    assert_equal [:click, :click, :submit], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :button, :form], dsl_attrs[:stimulus_targets]
  end

  def test_stimulus_block_with_string_and_symbol_mix
    @component_class.stimulus do
      actions :click, "submit", :toggle
      targets "button", :form, "input"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    assert_equal [:click, "submit", :toggle], dsl_attrs[:stimulus_actions]
    assert_equal ["button", :form, "input"], dsl_attrs[:stimulus_targets]
  end

  def test_values_with_mixed_hash_and_array
    @component_class.stimulus do
      values :auto_mapped_value
      values explicit_value: "explicit"
      values :another_auto_mapped
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { 
      auto_mapped_value: :auto_map_from_prop,
      explicit_value: "explicit",
      another_auto_mapped: :auto_map_from_prop
    }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_classes_with_multiple_calls
    @component_class.stimulus do
      classes loading: "opacity-50"
      classes active: "bg-blue-500", disabled: "cursor-not-allowed"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed" }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_outlets_with_multiple_calls
    @component_class.stimulus do
      outlets modal: ".modal"
      outlets tooltip: ".tooltip", dropdown: ".dropdown"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes
    expected = { modal: ".modal", tooltip: ".tooltip", dropdown: ".dropdown" }
    assert_equal expected, dsl_attrs[:stimulus_outlets]
  end
end