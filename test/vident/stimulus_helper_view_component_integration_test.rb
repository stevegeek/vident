# frozen_string_literal: true

require "test_helper"

class StimulusHelperViewComponentIntegrationTest < ViewComponent::TestCase
  include ::ActiveSupport::Testing::ConstantStubbing

  # Test ViewComponent that uses the stimulus DSL
  class TestButtonComponent < Vident::ViewComponent::Base
    prop :text, String, default: "Button"
    prop :disabled, _Boolean, default: false
    prop :loading, _Boolean, default: false
    prop :url, _Nilable(String)
    prop :method, String, default: "GET"

    stimulus do
      actions :click, :mouseenter, :mouseleave
      targets :button, :icon, :spinner
      values_from_props :text, :disabled, :loading, :url
      values method: "POST"
      classes(
        loading: "opacity-50 cursor-wait",
        disabled: "opacity-25 cursor-not-allowed",
        success: "bg-green-500",
        error: "bg-red-500"
      )
      outlets(modal: ".modal")
    end

    private def root_element_attributes
      {
        element_tag: :button
      }
    end

    def call
      root_element do
        @text
      end
    end
  end

  # Test ViewComponent exercising nil-vs-StimulusNull value emission
  class TestNullableValuesComponent < Vident::ViewComponent::Base
    prop :flag, _Boolean, default: false

    stimulus do
      values explicit_null: Vident::StimulusNull,
        static_nil: nil,
        dynamic_null: -> { Vident::StimulusNull },
        dynamic_nil: -> { @flag ? "on" : nil }
    end

    def call
      root_element { "Nullable" }
    end
  end

  # Test ViewComponent with multiple stimulus blocks
  class TestMultiBlockComponent < Vident::ViewComponent::Base
    prop :name, String
    prop :count, Integer, default: 0

    stimulus do
      actions :click, :focus
      targets :input
      values_from_props :name
    end

    stimulus do
      actions :blur, :change
      targets :output
      values_from_props :count
      classes active: "bg-blue-500"
    end

    def call
      root_element do
        "Multi Block Component"
      end
    end
  end

  # Test ViewComponent with inheritance
  class BaseComponent < Vident::ViewComponent::Base
    stimulus do
      actions :click
      targets :base
    end
  end

  class ChildComponent < BaseComponent
    prop :title, String

    stimulus do
      actions :submit
      targets :child
      values_from_props :title
    end

    def call
      root_element do
        @title
      end
    end
  end

  def test_dsl_attributes_collected_correctly
    dsl_attrs = TestButtonComponent.stimulus_dsl_attributes(TestButtonComponent.new)

    assert_equal [:click, :mouseenter, :mouseleave], dsl_attrs[:stimulus_actions]
    assert_equal [:button, :icon, :spinner], dsl_attrs[:stimulus_targets]

    expected_values = {method: "POST"}
    assert_equal expected_values, dsl_attrs[:stimulus_values]

    expected_values_from_props = [:text, :disabled, :loading, :url]
    assert_equal expected_values_from_props, dsl_attrs[:stimulus_values_from_props]

    expected_classes = {
      loading: "opacity-50 cursor-wait",
      disabled: "opacity-25 cursor-not-allowed",
      success: "bg-green-500",
      error: "bg-red-500"
    }
    assert_equal expected_classes, dsl_attrs[:stimulus_classes]

    assert_equal({modal: ".modal"}, dsl_attrs[:stimulus_outlets])
  end

  def test_component_instantiation_with_dsl
    component = TestButtonComponent.new(text: "Click me", disabled: true, url: "/test")
    assert_instance_of TestButtonComponent, component
    assert_equal "Click me", component.instance_variable_get(:@text)
    assert_equal true, component.instance_variable_get(:@disabled)
    assert_equal "/test", component.instance_variable_get(:@url)
  end

  def test_dsl_value_resolution
    component = TestButtonComponent.new(text: "Test", disabled: true, loading: false, url: "/api/test")

    # Test the prop mapping method
    values_from_props = component.class.stimulus_dsl_attributes(component)[:stimulus_values_from_props]
    resolved_from_props = component.send(:resolve_values_from_props, values_from_props)

    expected_from_props = {
      text: "Test",
      disabled: true,
      loading: false,
      url: "/api/test"
    }
    assert_equal expected_from_props, resolved_from_props

    # Test static values
    static_values = component.class.stimulus_dsl_attributes(component)[:stimulus_values]
    expected_static = {method: "POST"}
    assert_equal expected_static, static_values
  end

  def test_dsl_value_resolution_with_missing_props
    component = TestButtonComponent.new(text: "Test")  # Missing other props

    # Test prop mapping with defaults
    values_from_props = component.class.stimulus_dsl_attributes(component)[:stimulus_values_from_props]
    resolved_from_props = component.send(:resolve_values_from_props, values_from_props)

    expected_from_props = {
      text: "Test",
      disabled: false,  # default value
      loading: false,   # default value
      url: nil          # nil values are now included from props
    }
    assert_equal expected_from_props, resolved_from_props
  end

  def test_stimulus_data_attributes_integration
    component = TestButtonComponent.new(text: "Submit", disabled: false, loading: true, url: "/submit")

    # Trigger the prepare_component_attributes method
    component.send(:prepare_component_attributes)

    # Get the stimulus data attributes
    data_attrs = component.send(:stimulus_data_attributes)

    # Should have controller
    assert data_attrs.key?("controller")

    # Should have values from DSL
    text_key = data_attrs.keys.find { |k| k.include?("text-value") }
    assert text_key
    assert_equal "Submit", data_attrs[text_key]

    loading_key = data_attrs.keys.find { |k| k.include?("loading-value") }
    assert loading_key
    assert_equal "true", data_attrs[loading_key]

    method_key = data_attrs.keys.find { |k| k.include?("method-value") }
    assert method_key
    assert_equal "POST", data_attrs[method_key]

    # Should have classes
    loading_class_key = data_attrs.keys.find { |k| k.include?("loading-class") }
    assert loading_class_key
    assert_equal "opacity-50 cursor-wait", data_attrs[loading_class_key]
  end

  def test_cross_controller_stimulus_values_via_collection_prop
    component_class = Class.new(::Vident::ViewComponent::Base) do
      def self.name = "CrossControllerValuesComponent"

      def call
        root_element { "x" }
      end
    end

    component = component_class.new(
      stimulus_controllers: ["other_ui/modal_button"],
      stimulus_values: component_class.new.stimulus_values(
        ["other_ui/modal_button", :initial_content, "hi"],
        ["other_ui/modal_button", :content_href, "/foo"],
        ["other_ui/modal_button", :close_on_overlay_click, false]
      )
    )
    component.send(:prepare_component_attributes)
    data_attrs = component.send(:stimulus_data_attributes)

    assert_equal "hi", data_attrs["other-ui--modal-button-initial-content-value"]
    assert_equal "/foo", data_attrs["other-ui--modal-button-content-href-value"]
    assert_equal "false", data_attrs["other-ui--modal-button-close-on-overlay-click-value"]
  end

  def test_cross_controller_stimulus_values_via_array_prop
    component_class = Class.new(::Vident::ViewComponent::Base) do
      def self.name = "CrossControllerArrayValuesComponent"

      def call
        root_element { "x" }
      end
    end

    component = component_class.new(
      stimulus_controllers: ["other_ui/modal_button"],
      stimulus_values: [
        ["other_ui/modal_button", :initial_content, "hi"],
        ["other_ui/modal_button", :content_href, "/foo"]
      ]
    )
    component.send(:prepare_component_attributes)
    data_attrs = component.send(:stimulus_data_attributes)

    assert_equal "hi", data_attrs["other-ui--modal-button-initial-content-value"]
    assert_equal "/foo", data_attrs["other-ui--modal-button-content-href-value"]
  end

  def test_stimulus_null_sentinel_emits_null_string_nil_omits_attribute
    component = TestNullableValuesComponent.new(flag: false)
    component.send(:prepare_component_attributes)
    data_attrs = component.send(:stimulus_data_attributes)

    explicit_null_key = data_attrs.keys.find { |k| k.include?("explicit-null-value") }
    dynamic_null_key = data_attrs.keys.find { |k| k.include?("dynamic-null-value") }
    static_nil_key = data_attrs.keys.find { |k| k.include?("static-nil-value") }
    dynamic_nil_key = data_attrs.keys.find { |k| k.include?("dynamic-nil-value") }

    assert explicit_null_key, "StimulusNull sentinel should emit its data attribute"
    assert_equal "null", data_attrs[explicit_null_key]

    assert dynamic_null_key, "proc returning StimulusNull should emit its data attribute"
    assert_equal "null", data_attrs[dynamic_null_key]

    refute static_nil_key, "static nil value should be omitted from data attributes"
    refute dynamic_nil_key, "proc returning nil should be omitted from data attributes"
  end

  def test_html_rendering_with_dsl
    component = TestButtonComponent.new(text: "Test Button", disabled: true, loading: false)

    render_inline(component)

    # Should render button element
    assert_selector "button"

    # Should have text content
    assert_text "Test Button"

    # Should have stimulus controller
    assert_selector "button[data-controller]"

    # Should have stimulus values - using specific controller name for data attributes
    # Note: The exact controller name depends on component naming, so we'll test more generically
    assert_selector "button[data-controller*='test-button-component']"

    # Should have some stimulus data attributes
    assert page.has_css?("[data-controller]"), "Expected HTML to contain stimulus data attributes"
  end

  def test_outlets_rendered_as_data_attributes
    component = TestButtonComponent.new(text: "Outlet Test")

    render_inline(component)

    assert_match(/data-[\w-]+-modal-outlet="\.modal"/, rendered_content)
  end

  def test_outlets_with_string_identifier_rendered
    outlet_host_class = Class.new(Vident::ViewComponent::Base) do
      def self.name = "OutletStringKeyHostComponent"

      stimulus do
        outlets({"other-ns--sibling" => "[data-sibling]"})
      end

      def call
        root_element { "" }
      end
    end

    render_inline(outlet_host_class.new)

    assert_match(/data-[\w-]+-other-ns--sibling-outlet="\[data-sibling\]"/, rendered_content)
  end

  def test_multi_block_component_merging
    dsl_attrs = TestMultiBlockComponent.stimulus_dsl_attributes(TestMultiBlockComponent.new(name: "test"))

    # Actions from both blocks
    assert_equal [:click, :focus, :blur, :change], dsl_attrs[:stimulus_actions]

    # Targets from both blocks
    assert_equal [:input, :output], dsl_attrs[:stimulus_targets]

    # Values from both blocks
    expected_values_from_props = [:name, :count]
    assert_equal expected_values_from_props, dsl_attrs[:stimulus_values_from_props]

    # Classes from second block
    assert_equal({active: "bg-blue-500"}, dsl_attrs[:stimulus_classes])
  end

  def test_multi_block_component_rendering
    component = TestMultiBlockComponent.new(name: "Test", count: 5)

    render_inline(component)

    assert_selector "div"
    assert_text "Multi Block Component"

    # Should have stimulus controller
    assert_selector "div[data-controller]"
  end

  def test_inheritance_merging
    parent_attrs = BaseComponent.stimulus_dsl_attributes(BaseComponent.new)
    child_attrs = ChildComponent.stimulus_dsl_attributes(ChildComponent.new(title: "test"))

    # Parent should have its own attributes
    assert_equal [:click], parent_attrs[:stimulus_actions]
    assert_equal [:base], parent_attrs[:stimulus_targets]

    # Child should inherit parent's attributes and add its own
    assert_equal [:click, :submit], child_attrs[:stimulus_actions]
    assert_equal [:base, :child], child_attrs[:stimulus_targets]
    assert_equal([:title], child_attrs[:stimulus_values_from_props])
  end

  def test_inheritance_rendering
    component = ChildComponent.new(title: "Child Title")

    render_inline(component)

    assert_selector "div"
    assert_text "Child Title"

    # Should have inherited controller
    assert_selector "div[data-controller]"

    # Should have value from child
    assert page.has_css?("[data-controller*='child-component']"), "Expected child component controller"
  end

  def test_dsl_with_root_element_attributes_merging
    # Test that DSL attributes are merged with root_element_attributes
    component = TestButtonComponent.new(text: "Merge Test", loading: true)

    # Mock root_element_attributes to add additional stimulus attributes
    component.define_singleton_method(:root_element_attributes) do
      {
        element_tag: :button,
        html_options: {class: "btn btn-primary"},
        stimulus_actions: [:custom_action],
        stimulus_values: {custom: "value"}
      }
    end

    component.send(:prepare_component_attributes)
    data_attrs = component.send(:stimulus_data_attributes)

    # Should have DSL values
    text_key = data_attrs.keys.find { |k| k.include?("text-value") }
    assert text_key
    assert_equal "Merge Test", data_attrs[text_key]

    # Should have root_element_attributes values
    custom_key = data_attrs.keys.find { |k| k.include?("custom-value") }
    assert custom_key
    assert_equal "value", data_attrs[custom_key]
  end

  def test_empty_dsl_block_does_not_break_component
    klass = Class.new(Vident::ViewComponent::Base) do
      stimulus do
        # Empty block
      end

      def call
        content_tag :div, "Empty DSL"
      end
    end
    stub_const(::ViewComponent, :EmptyDSLTestComponent, klass, exists: false) do
      component = ::ViewComponent::EmptyDSLTestComponent.new

      # Should not raise any errors
      assert_nothing_raised do
        render_inline(component)
      end

      assert_selector "div"
      assert_text "Empty DSL"
    end
  end

  def test_stimulus_targets_prop_accepts_array_entries
    child_class = Class.new(Vident::ViewComponent::Base) do
      def self.name = "StimulusTargetsArrayTestComponent"

      def call
        root_element { "" }
      end
    end

    assert_nothing_raised do
      child_class.new(stimulus_targets: [["path/to/controller", :name]])
    end
  end

  def test_dsl_with_no_props_still_works
    # Define a proper named class to avoid ViewComponent demodulize issues
    klass = Class.new(Vident::ViewComponent::Base) do
      stimulus do
        actions :click
        targets :button
        values static: "value"
        classes active: "active"
      end

      private def root_element_attributes
        {
          element_tag: :button
        }
      end

      def call
        root_element do
          "No Props"
        end
      end
    end
    stub_const(::ViewComponent, :NoPropsTestComponent, klass, exists: false) do
      component = ::ViewComponent::NoPropsTestComponent.new

      render_inline(component)

      assert_selector "button"
      assert_text "No Props"

      # Should have static values and classes
      assert page.has_css?("button[data-controller]"), "Expected button to have stimulus controller"
      html_content = page.native.to_html
      assert html_content.include?("static-value=\"value\""), "Expected static value in HTML"
      assert html_content.include?("active-class=\"active\""), "Expected active class in HTML"
    end
  end
end
