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
    fresh_class = Class.new do
      include Vident::StimulusDSL
      def initialize; end
    end
    dsl_attrs = fresh_class.stimulus_dsl_attributes(fresh_class.new)
    
    assert_equal({}, dsl_attrs)
  end

  def test_stimulus_block_with_actions
    @component_class.stimulus do
      actions :click, :submit, :toggle
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    assert_equal [:click, :submit, :toggle], dsl_attrs[:stimulus_actions]
  end

  def test_stimulus_block_with_targets
    @component_class.stimulus do
      targets :button, :form, :input
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    assert_equal [:button, :form, :input], dsl_attrs[:stimulus_targets]
  end

  def test_stimulus_block_with_values_from_props
    @component_class.stimulus do
      values_from_props :name, :count, :active
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = [:name, :count, :active]
    assert_equal expected, dsl_attrs[:stimulus_values_from_props]
  end

  def test_stimulus_block_with_values_hash
    @component_class.stimulus do
      values name: "default", count: 0, active: true
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { name: "default", count: 0, active: true }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_stimulus_block_with_classes_hash
    @component_class.stimulus do
      classes loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed" }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_stimulus_block_with_outlets
    @component_class.stimulus do
      outlets modal: ".modal", tooltip: ".tooltip"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { modal: ".modal", tooltip: ".tooltip" }
    assert_equal expected, dsl_attrs[:stimulus_outlets]
  end

  def test_stimulus_block_with_mixed_attributes
    @component_class.stimulus do
      actions [:click, :submit], :edit
      targets :button, :form
      values count: 0, enabled: true
      values_from_props :name, :title
      classes loading: "opacity-50", active: "bg-blue-500"
      outlets modal: ".modal"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    
    assert_equal [[:click, :submit], :edit], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :form], dsl_attrs[:stimulus_targets]
    assert_equal({ count: 0, enabled: true }, dsl_attrs[:stimulus_values])
    assert_equal([:name, :title], dsl_attrs[:stimulus_values_from_props])
    assert_equal({ loading: "opacity-50", active: "bg-blue-500" }, dsl_attrs[:stimulus_classes])
    assert_equal({ modal: ".modal" }, dsl_attrs[:stimulus_outlets])
  end

  def test_multiple_stimulus_blocks_merge
    @component_class.stimulus do
      actions :click
      targets :button
      values count: 0
    end
    
    @component_class.stimulus do
      actions :submit
      targets :form
      values_from_props :name
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    
    assert_equal [:click, :submit], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :form], dsl_attrs[:stimulus_targets]
    assert_equal({ count: 0 }, dsl_attrs[:stimulus_values])
    assert_equal([:name], dsl_attrs[:stimulus_values_from_props])
  end

  def test_stimulus_block_inheritance
    parent_class = Class.new do
      include Vident::StimulusDSL
      def initialize; end
      stimulus do
        actions :click
        targets :button
      end
    end
    
    child_class = Class.new(parent_class) do
      def initialize; end
      stimulus do
        actions :submit
        targets :form
      end
    end
    
    parent_attrs = parent_class.stimulus_dsl_attributes(parent_class.new)
    child_attrs = child_class.stimulus_dsl_attributes(child_class.new)
    
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
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    # Empty block should return empty hash since no attributes are set
    assert_equal({}, dsl_attrs)
  end

  def test_stimulus_block_with_no_arguments
    @component_class.stimulus do
      actions
      targets
      values_from_props
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    # When called with no arguments, methods should not add any attributes
    assert_equal({}, dsl_attrs)
  end

  def test_stimulus_block_with_duplicate_values
    @component_class.stimulus do
      actions :click, :click, :submit
      targets :button, :button, :form
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    # Should preserve duplicates (the underlying system handles deduplication)
    assert_equal [:click, :click, :submit], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :button, :form], dsl_attrs[:stimulus_targets]
  end

  def test_stimulus_block_with_string_and_symbol_mix
    @component_class.stimulus do
      actions :click, "submit", :toggle
      targets "button", :form, "input"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    assert_equal [:click, "submit", :toggle], dsl_attrs[:stimulus_actions]
    assert_equal ["button", :form, "input"], dsl_attrs[:stimulus_targets]
  end

  def test_values_with_mixed_static_and_from_props
    @component_class.stimulus do
      values_from_props :auto_mapped_value, :another_auto_mapped
      values explicit_value: "explicit", count: 42
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    assert_equal({ explicit_value: "explicit", count: 42 }, dsl_attrs[:stimulus_values])
    assert_equal([:auto_mapped_value, :another_auto_mapped], dsl_attrs[:stimulus_values_from_props])
  end

  def test_classes_with_multiple_calls
    @component_class.stimulus do
      classes loading: "opacity-50"
      classes active: "bg-blue-500", disabled: "cursor-not-allowed"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { loading: "opacity-50", active: "bg-blue-500", disabled: "cursor-not-allowed" }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_outlets_with_multiple_calls
    @component_class.stimulus do
      outlets modal: ".modal"
      outlets tooltip: ".tooltip", dropdown: ".dropdown"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { modal: ".modal", tooltip: ".tooltip", dropdown: ".dropdown" }
    assert_equal expected, dsl_attrs[:stimulus_outlets]
  end

  def test_proc_values_evaluated_in_component_context
    @component_class.stimulus do
      values count: -> { @test_prop.length }
      values number: proc { @another_prop * 2 }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { count: 10, number: 84 }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_proc_classes_evaluated_in_component_context
    @component_class.stimulus do
      classes loading: -> { @test_prop == "test_value" ? "opacity-50" : "" }
      classes size: proc { @another_prop > 40 ? "large" : "small" }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { loading: "opacity-50", size: "large" }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_proc_actions_evaluated_in_component_context
    @component_class.stimulus do
      actions -> { @test_prop == "test_value" ? [:click, :submit] : :click },
              -> { :other }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = [[:click, :submit], :other]
    assert_equal expected, dsl_attrs[:stimulus_actions]
  end

  def test_proc_targets_evaluated_in_component_context
    @component_class.stimulus do
      targets -> { @another_prop > 20 ? :form : :button }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = [:form]
    assert_equal expected, dsl_attrs[:stimulus_targets]
  end

  def test_mixed_static_and_proc_values
    @component_class.stimulus do
      values static_value: "always_same"
      values dynamic_value: -> { @test_prop.upcase }
      values another_static: 42
      values another_dynamic: proc { @another_prop + 10 }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { 
      static_value: "always_same", 
      dynamic_value: "TEST_VALUE", 
      another_static: 42, 
      another_dynamic: 52 
    }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_mixed_static_and_proc_classes
    @component_class.stimulus do
      classes static_class: "always-present"
      classes dynamic_class: -> { @test_prop.present? ? "has-value" : "" }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { static_class: "always-present", dynamic_class: "has-value" }
    assert_equal expected, dsl_attrs[:stimulus_classes]
  end

  def test_proc_with_component_helper_method
    @component_class.class_eval do
      def custom_helper
        "helper_result"
      end
    end

    @component_class.stimulus do
      values helper_value: -> { custom_helper }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { helper_value: "helper_result" }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_proc_inheritance_with_parent_and_child_procs
    parent_class = Class.new do
      include Vident::StimulusDSL
      def initialize
        @parent_value = "parent"
      end
      
      stimulus do
        values parent_proc: -> { @parent_value.upcase }
      end
    end
    
    child_class = Class.new(parent_class) do
      def initialize
        super
        @child_value = "child"
      end
      
      stimulus do
        values child_proc: -> { @child_value.upcase }
      end
    end
    
    child_attrs = child_class.stimulus_dsl_attributes(child_class.new)
    expected = { parent_proc: "PARENT", child_proc: "CHILD" }
    assert_equal expected, child_attrs[:stimulus_values]
  end

  def test_proc_that_returns_nil_or_false
    @component_class.stimulus do
      values nil_value: -> { nil }
      values false_value: -> { false }
      classes nil_class: -> { nil }
      classes false_class: -> { false }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    assert_equal({ nil_value: nil, false_value: false }, dsl_attrs[:stimulus_values])
    assert_equal({ nil_class: nil, false_class: false }, dsl_attrs[:stimulus_classes])
  end

  def test_proc_with_complex_logic
    @component_class.class_eval do
      def initialize(**props)
        props.each { |key, value| instance_variable_set("@#{key}", value) }
        @test_prop = "test_value"
        @another_prop = 42
        @items = props[:items] || []
        @status = props[:status] || "pending"
      end
    end

    component = @component_class.new(items: [1, 2, 3], status: "active")

    @component_class.stimulus do
      values item_count: -> { @items.count }
      values status_message: -> { @status == "active" ? "Ready" : "Waiting" }
      classes size: -> { @items.count > 2 ? "large" : "small" }
      classes status: -> { "status-#{@status}" }
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(component)
    expected_values = { item_count: 3, status_message: "Ready" }
    expected_classes = { size: "large", status: "status-active" }
    
    assert_equal expected_values, dsl_attrs[:stimulus_values]
    assert_equal expected_classes, dsl_attrs[:stimulus_classes]
  end

  def test_proc_and_lambda_values_are_evaluated
    test_proc = proc { "proc value" }
    test_lambda = lambda { "lambda value" }
    
    @component_class.stimulus do
      values proc_value: test_proc, lambda_value: test_lambda
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = { proc_value: "proc value", lambda_value: "lambda value" }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_nil_values_in_dsl
    @component_class.stimulus do
      values explicit_nil: nil, empty_string: "", zero: 0, false_value: false
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
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
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = {
      array: [1, 2, 3],
      hash: { nested: "value" },
      numeric: 42,
      float: 3.14,
      string: "test"
    }
    assert_equal expected, dsl_attrs[:stimulus_values]
  end

  def test_inheritance_with_conflicting_dsl_attributes
    parent_class = Class.new do
      include Vident::StimulusDSL
      def initialize; end
      stimulus do
        actions :parent_action
        values parent_value: "parent", shared: "from_parent"
      end
    end
    
    child_class = Class.new(parent_class) do
      def initialize; end
      stimulus do
        actions :child_action
        values child_value: "child", shared: "from_child"
      end
    end
    
    child_attrs = child_class.stimulus_dsl_attributes(child_class.new)
    assert_equal [:parent_action, :child_action], child_attrs[:stimulus_actions]
    
    expected_values = {
      parent_value: "parent",
      shared: "from_child",
      child_value: "child"
    }
    assert_equal expected_values, child_attrs[:stimulus_values]
  end

  def test_mixed_argument_types_in_same_call
    @component_class.stimulus do
      actions :symbol, "string", 123, nil, true, false
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    expected = [:symbol, "string", 123, nil, true, false]
    assert_equal expected, dsl_attrs[:stimulus_actions]
  end

  def test_unicode_characters_in_names
    @component_class.stimulus do
      actions :ação, :事件, :действие
      targets :elemento, :要素, :элемент
      values título: "título", 名前: "名前", имя: "имя"
    end
    
    dsl_attrs = @component_class.stimulus_dsl_attributes(@component)
    assert_equal [:ação, :事件, :действие], dsl_attrs[:stimulus_actions]
    assert_equal [:elemento, :要素, :элемент], dsl_attrs[:stimulus_targets]
    expected_values = { título: "título", 名前: "名前", имя: "имя" }
    assert_equal expected_values, dsl_attrs[:stimulus_values]
  end
end