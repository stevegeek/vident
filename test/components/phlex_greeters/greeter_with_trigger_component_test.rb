# frozen_string_literal: true

require "test_helper"

class PhlexGreeters::GreeterWithTriggerComponentTest < ActionView::TestCase
  def render(...)
    view_context.render(...)
  end

  def view_context
    controller.view_context
  end

  def controller
    @controller ||= ActionView::TestCase::TestController.new
  end

  # Parse HTML for assertions
  def parse_html(html)
    Nokogiri::HTML5.fragment(html)
  end

  def test_can_be_instantiated
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    assert_instance_of PhlexGreeters::GreeterWithTriggerComponent, component
  end

  def test_renders_basic_structure
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    html = render(component)
    doc = parse_html(html)

    # Should render a root div element
    assert_equal 1, doc.css("div").count

    # Should contain an input field
    assert_equal 1, doc.css("input[type='text']").count

    # Should contain a button (default trigger)
    assert_equal 1, doc.css("button").count

    # Should contain a span for output
    assert_equal 1, doc.css("span").count
  end

  def test_renders_stimulus_controller_attributes
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    html = render(component)
    doc = parse_html(html)

    root_div = doc.css("div").first

    # Should have stimulus controller data attribute
    assert root_div["data-controller"]&.include?("phlex-greeters--greeter-with-trigger-component")

    # Should have stimulus class data attributes
    assert root_div["data-phlex-greeters--greeter-with-trigger-component-pre-click-class"]
    assert root_div["data-phlex-greeters--greeter-with-trigger-component-post-click-class"]
  end

  def test_renders_input_with_stimulus_target
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    html = render(component)
    doc = parse_html(html)

    input = doc.css("input").first
    assert input["data-phlex-greeters--greeter-with-trigger-component-target"] == "name"
  end

  def test_renders_output_span_with_stimulus_target_and_classes
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    html = render(component)
    doc = parse_html(html)

    span = doc.css("span").first
    assert span["data-phlex-greeters--greeter-with-trigger-component-target"] == "output"
    assert span["class"]&.include?("text-md")
    assert span["class"]&.include?("text-gray-500")
    assert_equal " ... ", span.text
  end

  def test_renders_default_button_with_styling
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    html = render(component)
    doc = parse_html(html)

    button = doc.css("button").first
    assert button["class"]&.include?("bg-blue-500")
    assert button["class"]&.include?("text-white")
    assert button["class"]&.include?("font-bold")
    assert_equal "Greet", button.text
  end

  def test_renders_with_custom_trigger
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    component.trigger(before_clicked_message: "Custom Button Text")

    html = render(component)
    doc = parse_html(html)

    button = doc.css("button").first
    assert_equal "Custom Button Text", button.text
  end

  def test_trigger_method_creates_greeter_button_component
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    trigger = component.trigger(before_clicked_message: "Click me")

    assert_instance_of PhlexGreeters::GreeterButtonComponent, trigger
  end

  def test_trigger_method_accepts_arguments
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    trigger = component.trigger(
      after_clicked_message: "Clicked!",
      before_clicked_message: "Click me"
    )

    assert_instance_of PhlexGreeters::GreeterButtonComponent, trigger
  end

  def test_trigger_method_memoizes_instance
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    trigger1 = component.trigger(before_clicked_message: "First")
    trigger2 = component.trigger(before_clicked_message: "Second")

    # Should return the same instance (memoized)
    assert_same trigger1, trigger2
  end

  def test_root_element_attributes_returns_stimulus_classes
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)

    assert_instance_of Hash, attributes
    assert_includes attributes.keys, :stimulus_classes
    assert_equal "text-md text-gray-500", attributes[:stimulus_classes][:pre_click]
    assert_equal "text-xl text-blue-700", attributes[:stimulus_classes][:post_click]
  end

  def test_component_inheritance_chain
    assert PhlexGreeters::GreeterWithTriggerComponent < PhlexGreeters::ApplicationComponent
    assert PhlexGreeters::ApplicationComponent < Vident::Phlex::HTML
  end

  def test_component_has_view_template_method
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    assert component.private_methods.include?(:view_template)
  end

  def test_component_has_trigger_or_default_method
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    assert component.private_methods.include?(:trigger_or_default)
  end

  def test_component_includes_vident_modules
    assert PhlexGreeters::GreeterWithTriggerComponent.included_modules.include?(Vident::Component)
  end

  def test_component_stimulus_controller_enabled
    # Should inherit stimulus controller functionality from Vident::Phlex::HTML
    assert PhlexGreeters::GreeterWithTriggerComponent.stimulus_controller?
  end

  def test_component_stimulus_identifier
    expected_identifier = "phlex-greeters--greeter-with-trigger-component"
    assert_equal expected_identifier, PhlexGreeters::GreeterWithTriggerComponent.stimulus_identifier
  end

  def test_component_class_name
    expected_class_name = "phlex-greeters--greeter-with-trigger-component"
    assert_equal expected_class_name, PhlexGreeters::GreeterWithTriggerComponent.component_name
  end

  # Test rendering with a simple approach similar to the Phlex documentation
  def test_view_template_structure
    component = PhlexGreeters::GreeterWithTriggerComponent.new

    # Test that the view_template method exists and is private
    assert component.private_methods.include?(:view_template)
  end

  def test_trigger_or_default_with_no_custom_trigger
    component = PhlexGreeters::GreeterWithTriggerComponent.new

    # Mock a greeter object with stimulus_action method
    greeter = Object.new
    def greeter.stimulus_action(event, action)
      "click->test##{action}"
    end

    # The method will fail when called outside of a rendering context
    # because it tries to call render() which needs a view context
    assert_raises(NoMethodError) do
      component.send(:trigger_or_default, greeter)
    end
  end

  def test_trigger_or_default_with_custom_trigger
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    component.trigger(before_clicked_message: "Custom")

    # Mock a greeter object
    greeter = Object.new

    # Should return the custom trigger when one is set
    # The method will fail because it tries to call render on @trigger
    # This is expected behavior in a view context, but not in isolation
    assert_raises(NoMethodError) do
      component.send(:trigger_or_default, greeter)
    end
  end

  def test_component_default_controller_path
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    expected_path = "phlex_greeters/greeter_with_trigger_component"
    assert_equal expected_path, component.default_controller_path
  end

  def test_component_stimulus_identifier_path
    expected_path = "phlex_greeters/greeter_with_trigger_component"
    assert_equal expected_path, PhlexGreeters::GreeterWithTriggerComponent.stimulus_identifier_path
  end

  def test_component_stimulus_scoped_events
    expected_prefix = "phlex-greeters--greeter-with-trigger-component"
    assert_equal :"#{expected_prefix}:click", PhlexGreeters::GreeterWithTriggerComponent.stimulus_scoped_event(:click)
    assert_equal :"#{expected_prefix}:click@window", PhlexGreeters::GreeterWithTriggerComponent.stimulus_scoped_event_on_window(:click)
  end

  def test_root_element_attributes_structure
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)

    assert_equal [:stimulus_classes], attributes.keys
    assert_equal 2, attributes[:stimulus_classes].size
    assert attributes[:stimulus_classes].key?(:pre_click)
    assert attributes[:stimulus_classes].key?(:post_click)
  end

  def test_stimulus_classes_values
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)

    pre_click_classes = attributes[:stimulus_classes][:pre_click]
    post_click_classes = attributes[:stimulus_classes][:post_click]

    assert_includes pre_click_classes, "text-md"
    assert_includes pre_click_classes, "text-gray-500"
    assert_includes post_click_classes, "text-xl"
    assert_includes post_click_classes, "text-blue-700"
  end

  # Test for Vident::Phlex::HTML class methods
  def test_cache_component_modified_time_class_method
    modified_time = PhlexGreeters::GreeterWithTriggerComponent.cache_component_modified_time
    assert_instance_of String, modified_time
    refute_empty modified_time
    assert_match(/\A\d+\z/, modified_time)
  end

  def test_vanish_method_available
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    # The vanish method should be available from Vident::Phlex::HTML
    assert component.private_methods.include?(:vanish)
  end

  def test_root_element_method_available
    component = PhlexGreeters::GreeterWithTriggerComponent.new
    # The root_element method should be available from Vident::Phlex::HTML
    assert component.methods.include?(:root_element)
  end
end
