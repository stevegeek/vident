# frozen_string_literal: true

require "test_helper"

class Greeters::GreeterWithTriggerComponentTest < ViewComponent::TestCase
  def test_renders_component_with_basic_structure
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # Should render a div root element (default)
    assert_selector "div"

    # Should contain an input field for the name
    assert_selector "input[type='text']"

    # Should contain the output span with ellipsis
    assert_selector "span", text: "..."

    # Should contain a button (default trigger)
    assert_selector "button"
  end

  def test_renders_with_default_trigger
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # Should render the default trigger button with the fixed message
    assert_selector "button", text: "I'm the trigger! Click me to greet."
  end

  def test_renders_with_custom_trigger
    render_inline(Greeters::GreeterWithTriggerComponent.new) do |component|
      component.with_trigger(
        after_clicked_message: "Custom greeted!",
        before_clicked_message: "Custom greet"
      )
    end

    # Should render the custom trigger button
    assert_selector "button", text: "Custom greet"
  end

  def test_input_has_stimulus_target_attribute
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The input should have the stimulus target data attribute
    assert_selector "input[data-greeters--greeter-with-trigger-component-target='name']"
  end

  def test_output_span_has_stimulus_target_attribute
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The output span should have the stimulus target data attribute
    assert_selector "span[data-greeters--greeter-with-trigger-component-target='output']"
  end

  def test_output_span_has_stimulus_classes
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The output span should have the pre_click stimulus classes applied
    assert_selector "span.text-md.text-gray-500"
  end

  def test_trigger_has_stimulus_action_when_no_custom_trigger
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The default trigger should have stimulus action for greet
    assert_selector "button[data-action*='greeters--greeter-with-trigger-component#greet']"
  end

  def test_rendered_component_has_stimulus_controller_data_attribute
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The root element should have the stimulus controller data attribute
    assert_selector "div[data-controller='greeters--greeter-with-trigger-component']"
  end

  def test_rendered_component_has_stimulus_classes_data_attributes
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The root element should have stimulus class data attributes
    assert_selector "div[data-greeters--greeter-with-trigger-component-pre-click-class='text-md text-gray-500']"
    assert_selector "div[data-greeters--greeter-with-trigger-component-post-click-class='text-xl text-blue-700']"
  end

  def test_component_with_custom_html_options
    render_inline(Greeters::GreeterWithTriggerComponent.new(
      html_options: {class: "custom-class", id: "custom-id"}
    ))

    # Should include custom classes and id
    assert_selector "div.custom-class#custom-id"
  end

  def test_component_with_custom_element_tag
    render_inline(Greeters::GreeterWithTriggerComponent.new(element_tag: :section))

    # Should render as section instead of div
    assert_selector "section"
    assert_no_selector "div"
  end

  def test_component_with_id_prop
    render_inline(Greeters::GreeterWithTriggerComponent.new(id: "my-greeter"))

    # Should have the specified id
    assert_selector "div#my-greeter"
  end

  def test_trigger_slot_renders_greeter_button_component
    render_inline(Greeters::GreeterWithTriggerComponent.new) do |component|
      component.with_trigger(before_clicked_message: "Custom button")
    end

    # Should render a GreeterButtonComponent which has specific styling
    assert_selector "button.bg-blue-500", text: "Custom button"
  end

  def test_component_uses_as_stimulus_target_helper
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # Should use the as_stimulus_target helper which generates data attributes
    assert_selector "input[data-greeters--greeter-with-trigger-component-target='name']"
  end

  def test_component_uses_stimulus_action_helper
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The template uses stimulus_action helper to generate actions
    assert_selector "button[data-action*='click']"
    assert_selector "button[data-action*='greet']"
  end

  def test_component_uses_class_list_for_stimulus_classes_helper
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The template uses class_list_for_stimulus_classes helper
    # which should apply the pre_click classes from root_element_attributes
    assert_selector "span.text-md.text-gray-500"
  end

  def test_component_uses_tag_helper_for_span
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The template uses the tag helper to render the output span
    assert_selector "span[data-greeters--greeter-with-trigger-component-target='output']"
    assert_text "..."
  end

  def test_trigger_conditional_rendering_without_custom_trigger
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # When no trigger is provided, should render default trigger
    assert_selector "button", text: "I'm the trigger! Click me to greet."
  end

  def test_trigger_conditional_rendering_with_custom_trigger
    render_inline(Greeters::GreeterWithTriggerComponent.new) do |component|
      component.with_trigger(before_clicked_message: "Custom")
    end

    # When custom trigger is provided, should render the custom trigger
    assert_selector "button", text: "Custom"
  end

  def test_default_trigger_has_role_attribute
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The default trigger should have the role="button" attribute from html_options
    assert_selector "button[role='button']"
  end

  def test_default_trigger_has_stimulus_actions_array
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # The default trigger should have stimulus actions from the array
    assert_selector "button[data-action*='click->greeters--greeter-with-trigger-component#greet']"
  end

  def test_trigger_button_styling_from_greeter_button_component
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # Should render with GreeterButtonComponent's characteristic styling
    assert_selector "button.bg-blue-500"
    assert_selector "button.hover\\:bg-blue-700"
    assert_selector "button.text-white"
    assert_selector "button.font-bold"
    assert_selector "button.py-2"
    assert_selector "button.px-4"
    assert_selector "button.rounded"
  end

  def test_vident_view_component_base_methods_are_available
    render_inline(Greeters::GreeterWithTriggerComponent.new)

    # Test that Vident::ViewComponent::Base methods are working
    # The as_stimulus_target method should generate proper data attributes
    assert_selector "input[data-greeters--greeter-with-trigger-component-target='name']"

    # The tag helper should work for creating elements with stimulus attributes
    assert_selector "span[data-greeters--greeter-with-trigger-component-target='output']"
  end

  # Tests from the simple test file - component instantiation and basic properties
  def test_can_be_instantiated_with_minimal_required_props
    component = Greeters::GreeterWithTriggerComponent.new
    assert_instance_of Greeters::GreeterWithTriggerComponent, component
  end

  def test_root_element_attributes_method
    component = Greeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)

    assert_instance_of Hash, attributes
    assert_instance_of Hash, attributes[:stimulus_classes]
    assert_equal "text-md text-gray-500", attributes[:stimulus_classes][:pre_click]
    assert_equal "text-xl text-blue-700", attributes[:stimulus_classes][:post_click]
  end

  def test_component_stimulus_controller_enabled
    assert Greeters::GreeterWithTriggerComponent.stimulus_controller?
  end

  def test_component_stimulus_identifier
    expected_identifier = "greeters--greeter-with-trigger-component"
    assert_equal expected_identifier, Greeters::GreeterWithTriggerComponent.stimulus_identifier
  end

  def test_component_class_name
    expected_class_name = "greeters--greeter-with-trigger-component"
    assert_equal expected_class_name, Greeters::GreeterWithTriggerComponent.component_name
  end

  def test_component_inheritance_chain
    assert Greeters::GreeterWithTriggerComponent < Greeters::ApplicationComponent
    assert Greeters::ApplicationComponent < Vident::ViewComponent::Base
    assert Vident::ViewComponent::Base < ViewComponent::Base
  end

  def test_component_includes_vident_modules
    assert Greeters::GreeterWithTriggerComponent.included_modules.include?(Vident::Component)
  end

  def test_component_with_custom_id
    component = Greeters::GreeterWithTriggerComponent.new(id: "my-greeter")
    assert_equal "my-greeter", component.id
  end

  def test_trigger_slot_responds_to_methods
    component = Greeters::GreeterWithTriggerComponent.new
    assert_respond_to component, :trigger
    assert_respond_to component, :with_trigger
  end

  def test_component_default_controller_path
    component = Greeters::GreeterWithTriggerComponent.new
    expected_path = "greeters/greeter_with_trigger_component"
    assert_equal expected_path, component.default_controller_path
  end

  def test_component_stimulus_identifier_path
    expected_path = "greeters/greeter_with_trigger_component"
    assert_equal expected_path, Greeters::GreeterWithTriggerComponent.stimulus_identifier_path
  end

  def test_component_stimulus_scoped_events
    expected_prefix = "greeters--greeter-with-trigger-component"
    assert_equal "#{expected_prefix}:click", Greeters::GreeterWithTriggerComponent.stimulus_scoped_event(:click)
    assert_equal "#{expected_prefix}:click@window", Greeters::GreeterWithTriggerComponent.stimulus_scoped_event_on_window(:click)
  end

  def test_root_element_attributes_structure
    component = Greeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)

    assert_equal [:stimulus_classes], attributes.keys
    assert_equal 2, attributes[:stimulus_classes].size
    assert attributes[:stimulus_classes].key?(:pre_click)
    assert attributes[:stimulus_classes].key?(:post_click)
  end

  def test_stimulus_classes_values
    component = Greeters::GreeterWithTriggerComponent.new
    attributes = component.send(:root_element_attributes)

    pre_click_classes = attributes[:stimulus_classes][:pre_click]
    post_click_classes = attributes[:stimulus_classes][:post_click]

    assert_includes pre_click_classes, "text-md"
    assert_includes pre_click_classes, "text-gray-500"
    assert_includes post_click_classes, "text-xl"
    assert_includes post_click_classes, "text-blue-700"
  end

  # Tests for Vident::ViewComponent::Base class methods
  def test_component_path_class_method
    expected_path = Rails.root.join("app/components", "greeters/greeter_with_trigger_component.rb").to_s
    assert_equal expected_path, Greeters::GreeterWithTriggerComponent.component_path
    assert_match %r{test/dummy/app/components/greeters/greeter_with_trigger_component\.rb$}, Greeters::GreeterWithTriggerComponent.component_path
  end

  def test_template_path_class_method
    expected_path = Rails.root.join("app/components", "greeters/greeter_with_trigger_component.erb").to_s
    assert_equal expected_path, Greeters::GreeterWithTriggerComponent.template_path
    assert_match %r{test/dummy/app/components/greeters/greeter_with_trigger_component\.erb$}, Greeters::GreeterWithTriggerComponent.template_path
  end

  def test_components_base_path_class_method
    expected_path = "app/components"
    assert_equal expected_path, Greeters::GreeterWithTriggerComponent.components_base_path
  end

  def test_cache_component_modified_time_class_method
    modified_time = Greeters::GreeterWithTriggerComponent.cache_component_modified_time
    assert_instance_of String, modified_time

    refute_empty modified_time, "Modified time should not be empty when both component and template files exist"
    assert_match(/\A\d+\z/, modified_time)

    assert modified_time.length > 10, "Should be concatenated timestamps from both files"
  end

  def test_cache_sidecar_view_modified_time_class_method
    modified_time = Greeters::GreeterWithTriggerComponent.cache_sidecar_view_modified_time
    assert_instance_of String, modified_time

    refute_empty modified_time, "Should return modified time for existing .erb template"
    assert_match(/\A\d+\z/, modified_time)
  end

  def test_cache_rb_component_modified_time_class_method
    modified_time = Greeters::GreeterWithTriggerComponent.cache_rb_component_modified_time
    assert_instance_of String, modified_time

    refute_empty modified_time, "Should return modified time for existing component"
    assert_match(/\A\d+\z/, modified_time)
  end
end
