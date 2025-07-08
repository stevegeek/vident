# frozen_string_literal: true

require "test_helper"

class StimulusHelperPhlexIntegrationTest < ActionView::TestCase
  # Helper method to render Phlex components
  def render(component)
    component.call
  end

  # Test Phlex component that uses the stimulus DSL
  class TestCardComponent < Vident::Phlex::HTML
    prop :title, String, default: "Card"
    prop :collapsed, _Boolean, default: false
    prop :loading, _Boolean, default: false
    prop :url, _Nilable(String)
    prop :variant, String, default: "default"

    stimulus do
      actions :click, :toggle, :expand, :collapse
      targets :header, :body, :toggle_button, :spinner
      values_from_props :title, :collapsed, :loading, :url
      values variant: "card"
      classes(
        collapsed: "h-16 overflow-hidden",
        expanded: "h-auto",
        loading: "opacity-60 pointer-events-none",
        error: "border-red-500 bg-red-50",
        success: "border-green-500 bg-green-50"
      )
      outlets(notification: "[data-controller='notification']")
    end

    def view_template
      root_element do |component|
        div(class: "card-header", data: component.stimulus_target(:header).to_h) do
          h3 { @title }
          button(data: component.stimulus_target(:toggle_button).to_h) { "Toggle" }
        end
        div(class: "card-body", data: component.stimulus_target(:body).to_h) do
          if @loading
            div(data: component.stimulus_target(:spinner).to_h) { "Loading..." }
          else
            p { "Card content here" }
          end
        end
      end
    end
  end

  # Test Phlex component with multiple stimulus blocks
  class TestFormComponent < Vident::Phlex::HTML
    prop :action, String, default: "/submit"
    prop :method, String, default: "POST"
    prop :disabled, _Boolean, default: false

    stimulus do
      actions :submit, :reset
      targets :form, :submit_button
      values_from_props :action
    end

    stimulus do
      actions :change, :input
      targets :input, :error
      values_from_props :method, :disabled
      classes invalid: "border-red-500", valid: "border-green-500"
    end

    def root_element_attributes
      {element_tag: :form}
    end

    def view_template
      root_element do |component|
        input(type: "text", data: component.stimulus_target(:input).to_h)
        div(data: component.stimulus_target(:error).to_h) # error container
        button(type: "submit", data: component.stimulus_target(:submit_button).to_h) { "Submit" }
      end
    end
  end

  # Test Phlex inheritance
  class BasePhlexComponent < Vident::Phlex::HTML
    stimulus do
      actions :click
      targets :base
      classes active: "active"
    end
  end

  class ChildPhlexComponent < BasePhlexComponent
    prop :content, String, default: "Child content"

    stimulus do
      actions :hover
      targets :child
      values_from_props :content
    end

    def view_template
      root_element do |component|
        span(data: component.stimulus_target(:base).to_h) { "Base" }
        span(data: component.stimulus_target(:child).to_h) { @content }
      end
    end
  end

  def test_phlex_dsl_attributes_collected_correctly
    dsl_attrs = TestCardComponent.stimulus_dsl_attributes(TestCardComponent.new)

    assert_equal [:click, :toggle, :expand, :collapse], dsl_attrs[:stimulus_actions]
    assert_equal [:header, :body, :toggle_button, :spinner], dsl_attrs[:stimulus_targets]

    expected_values = {variant: "card"}
    assert_equal expected_values, dsl_attrs[:stimulus_values]

    expected_values_from_props = [:title, :collapsed, :loading, :url]
    assert_equal expected_values_from_props, dsl_attrs[:stimulus_values_from_props]

    expected_classes = {
      collapsed: "h-16 overflow-hidden",
      expanded: "h-auto",
      loading: "opacity-60 pointer-events-none",
      error: "border-red-500 bg-red-50",
      success: "border-green-500 bg-green-50"
    }
    assert_equal expected_classes, dsl_attrs[:stimulus_classes]

    assert_equal({notification: "[data-controller='notification']"}, dsl_attrs[:stimulus_outlets])
  end

  def test_phlex_component_instantiation_with_dsl
    component = TestCardComponent.new(title: "Test Card", collapsed: true, url: "/test")
    assert_instance_of TestCardComponent, component
    assert_equal "Test Card", component.instance_variable_get(:@title)
    assert_equal true, component.instance_variable_get(:@collapsed)
    assert_equal "/test", component.instance_variable_get(:@url)
  end

  def test_phlex_dsl_value_resolution
    component = TestCardComponent.new(title: "My Card", collapsed: false, loading: true, url: "/api/card")

    # Test prop mapping
    values_from_props = component.class.stimulus_dsl_attributes(component)[:stimulus_values_from_props]
    resolved_from_props = component.send(:resolve_values_from_props, values_from_props)

    expected_from_props = {
      title: "My Card",
      collapsed: false,
      loading: true,
      url: "/api/card"
    }
    assert_equal expected_from_props, resolved_from_props

    # Test static values
    static_values = component.class.stimulus_dsl_attributes(component)[:stimulus_values]
    expected_static = {variant: "card"}
    assert_equal expected_static, static_values
  end

  def test_phlex_stimulus_data_attributes_integration
    component = TestCardComponent.new(title: "Integration Test", collapsed: true, loading: false)

    component.send(:prepare_component_attributes)
    data_attrs = component.send(:stimulus_data_attributes)

    # Should have controller
    assert data_attrs.key?("controller")

    # Should have values from DSL
    title_key = data_attrs.keys.find { |k| k.include?("title-value") }
    assert title_key
    assert_equal "Integration Test", data_attrs[title_key]

    collapsed_key = data_attrs.keys.find { |k| k.include?("collapsed-value") }
    assert collapsed_key
    assert_equal "true", data_attrs[collapsed_key]

    variant_key = data_attrs.keys.find { |k| k.include?("variant-value") }
    assert variant_key
    assert_equal "card", data_attrs[variant_key]

    # Should have classes
    collapsed_class_key = data_attrs.keys.find { |k| k.include?("collapsed-class") }
    assert collapsed_class_key
    assert_equal "h-16 overflow-hidden", data_attrs[collapsed_class_key]
  end

  def test_phlex_html_rendering_with_dsl
    component = TestCardComponent.new(title: "Render Test", collapsed: false, loading: true)
    output = render component

    # Should have stimulus controller
    assert_includes output, "data-controller"

    # Should have stimulus values
    assert_includes output, "data-"
    assert_includes output, 'title-value="Render Test"'
    assert_includes output, 'collapsed-value="false"'
    assert_includes output, 'loading-value="true"'
    assert_includes output, 'variant-value="card"'

    # Should have content
    assert_includes output, "Render Test"
    assert_includes output, "Loading..."
    assert_includes output, "Toggle"
  end

  def test_phlex_stimulus_targets_work_correctly
    component = TestCardComponent.new(title: "Target Test")
    output = render component

    # Should have stimulus targets
    assert_includes output, "data-"
    assert_includes output, "-target"

    # Check that targets are properly applied to elements
    # The exact format depends on the controller name, but targets should be present
    assert_match(/data-[^=]+-target="[^"]*header[^"]*"/, output)
    assert_match(/data-[^=]+-target="[^"]*body[^"]*"/, output)
    assert_match(/data-[^=]+-target="[^"]*toggleButton[^"]*"/, output)
  end

  def test_phlex_multi_block_component_merging
    dsl_attrs = TestFormComponent.stimulus_dsl_attributes(TestFormComponent.new)

    # Actions from both blocks
    assert_equal [:submit, :reset, :change, :input], dsl_attrs[:stimulus_actions]

    # Targets from both blocks
    assert_equal [:form, :submit_button, :input, :error], dsl_attrs[:stimulus_targets]

    # Values from both blocks
    expected_values_from_props = [:action, :method, :disabled]
    assert_equal expected_values_from_props, dsl_attrs[:stimulus_values_from_props]

    # Classes from second block
    expected_classes = {invalid: "border-red-500", valid: "border-green-500"}
    assert_equal expected_classes, dsl_attrs[:stimulus_classes]
  end

  def test_phlex_multi_block_rendering
    component = TestFormComponent.new(action: "/api/submit", method: "PATCH", disabled: false)
    output = render component

    # Should have values from both blocks
    assert_includes output, 'action-value="/api/submit"'
    assert_includes output, 'method-value="PATCH"'
    assert_includes output, 'disabled-value="false"'

    # Should have classes
    assert_includes output, 'invalid-class="border-red-500"'
    assert_includes output, 'valid-class="border-green-500"'

    # Should have form elements
    assert_includes output, "<form"
    assert_includes output, 'type="text"'
    assert_includes output, 'type="submit"'
  end

  def test_phlex_inheritance_merging
    parent_attrs = BasePhlexComponent.stimulus_dsl_attributes(BasePhlexComponent.new)
    child_attrs = ChildPhlexComponent.stimulus_dsl_attributes(ChildPhlexComponent.new)

    # Parent should have its own attributes
    assert_equal [:click], parent_attrs[:stimulus_actions]
    assert_equal [:base], parent_attrs[:stimulus_targets]
    assert_equal({active: "active"}, parent_attrs[:stimulus_classes])

    # Child should inherit parent's attributes and add its own
    assert_equal [:click, :hover], child_attrs[:stimulus_actions]
    assert_equal [:base, :child], child_attrs[:stimulus_targets]
    assert_equal([:content], child_attrs[:stimulus_values_from_props])
    assert_equal({active: "active"}, child_attrs[:stimulus_classes])
  end

  def test_phlex_inheritance_rendering
    component = ChildPhlexComponent.new(content: "Child Test Content")
    output = render component

    # Should have inherited controller
    assert_includes output, "data-controller"

    # Should have value from child
    assert_includes output, 'content-value="Child Test Content"'

    # Should have classes from parent
    assert_includes output, 'active-class="active"'

    # Should have content
    assert_includes output, "Base"
    assert_includes output, "Child Test Content"
  end

  def test_phlex_dsl_with_root_element_attributes_merging
    component = TestCardComponent.new(title: "Merge Test", loading: true)

    # Mock root_element_attributes to add additional stimulus attributes
    component.define_singleton_method(:root_element_attributes) do
      {
        element_tag: :div,
        html_options: {class: "card bg-white shadow"},
        stimulus_actions: [:custom_action],
        stimulus_values: {custom: "value"}
      }
    end

    component.send(:prepare_component_attributes)
    data_attrs = component.send(:stimulus_data_attributes)

    # Should have DSL values
    title_key = data_attrs.keys.find { |k| k.include?("title-value") }
    assert title_key
    assert_equal "Merge Test", data_attrs[title_key]

    # Should have root_element_attributes values
    custom_key = data_attrs.keys.find { |k| k.include?("custom-value") }
    assert custom_key
    assert_equal "value", data_attrs[custom_key]
  end

  def test_phlex_empty_dsl_block_does_not_break_component
    component_class = Class.new(Vident::Phlex::HTML) do
      stimulus do
        # Empty block
      end

      def view_template
        div { "Empty DSL" }
      end
    end

    component = component_class.new

    # Should not raise any errors
    assert_nothing_raised do
      render component
    end

    # Create a new instance for the second render
    output = render component_class.new
    assert_includes output, "Empty DSL"
  end

  def test_phlex_dsl_with_no_props_still_works
    component_class = Class.new(Vident::Phlex::HTML) do
      stimulus do
        actions :click
        targets :button
        values static: "value"
        classes active: "active"
      end

      def root_element_attributes
        {element_tag: :button}
      end

      def view_template
        root_element do
          "No Props"
        end
      end
    end

    component = component_class.new
    output = render component

    # Should have static values
    assert_includes output, 'static-value="value"'
    assert_includes output, 'active-class="active"'
    assert_includes output, "No Props"
  end

  def test_phlex_complex_nested_targets
    component = TestCardComponent.new(title: "Nested Test", loading: false)
    output = render component

    # Should have properly nested elements with targets
    assert_includes output, "card-header"
    assert_includes output, "card-body"

    # Should have multiple targets on different elements (excluding the root element's target list)
    # Look for individual target assignments, not the root element's comprehensive target list
    header_matches = output.scan(/class="card-header"[^>]*data-[^=]+-target="header"/).length
    body_matches = output.scan(/class="card-body"[^>]*data-[^=]+-target="body"/).length
    button_matches = output.scan(/<button[^>]*data-[^=]+-target="toggleButton"/).length

    assert_equal 1, header_matches
    assert_equal 1, body_matches
    assert_equal 1, button_matches
  end

  def test_phlex_conditional_content_with_dsl
    # Test with loading = true
    loading_component = TestCardComponent.new(title: "Loading Test", loading: true)
    loading_output = render loading_component

    assert_includes loading_output, "Loading..."
    assert_includes loading_output, 'loading-value="true"'

    # Test with loading = false
    normal_component = TestCardComponent.new(title: "Normal Test", loading: false)
    normal_output = render normal_component

    assert_includes normal_output, "Card content here"
    assert_includes normal_output, 'loading-value="false"'
    refute_includes normal_output, "Loading..."
  end
end
