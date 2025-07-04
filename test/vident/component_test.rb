require "test_helper"

module Vident
  class ComponentTest < Minitest::Test
    class TestHelpers
      def params
        {}
      end
    end

    class TestRoot
      def action
        "action_result"
      end

      def target
        "target_result"
      end

      def named_classes
        "named_classes_result"
      end
    end

    def setup
      # Create a test component class that includes Component
      @test_component_class = Class.new do
        include Vident::Component

        def self.name
          "TestComponent"
        end

        def attribute(name)
          case name
          when :html_options
            @html_options
          when :actions, :targets, :controllers, :outlets, :values
            []
          when :named_classes
            {}
          when :id
            @id
          end
        end

        def to_h
          {name: "test", value: 42}
        end

        def helpers
          TestHelpers.new
        end

        def root
          @root ||= TestRoot.new
        end

        def produce_style_classes(classes)
          dedupe_view_component_classes(classes)
        end

        def get_all_data_attrs
          tag_data_attributes
        end

        private

        def dedupe_view_component_classes(html_classes)
          html_classes.reject!(&:blank?)
          html_classes.map! { |x| x.include?(" ") ? x.split(" ") : x }
            .flatten!
          html_classes.uniq!
          html_classes.present? ? html_classes.join(" ") : nil
        end
      end

      @component = @test_component_class.new
    end

    # Test class methods
    def test_stimulus_controller_default_true
      assert @test_component_class.stimulus_controller?
    end

    def test_no_stimulus_controller
      test_class = Class.new do
        include Vident::Component
        no_stimulus_controller
      end

      refute test_class.stimulus_controller?
    end

    def test_stimulus_identifier_path
      assert_equal "test_component", @test_component_class.stimulus_identifier_path
    end

    def test_stimulus_identifier
      expected = "test-component"
      assert_equal expected, @test_component_class.stimulus_identifier
    end

    def test_component_name
      assert_equal "test-component", @test_component_class.component_name
    end

    def test_component_class_name_alias
      assert_equal @test_component_class.component_name, @test_component_class.component_class_name
    end

    def test_js_event_name_prefix_alias
      assert_equal @test_component_class.component_name, @test_component_class.js_event_name_prefix
    end

    # Test stimulus_identifier_from_path module function
    def test_stimulus_identifier_from_path_simple
      result = Vident::Component.stimulus_identifier_from_path("my_component")
      assert_equal "my-component", result
    end

    def test_stimulus_identifier_from_path_nested
      result = Vident::Component.stimulus_identifier_from_path("admin/user_profile")
      assert_equal "admin--user-profile", result
    end

    def test_stimulus_identifier_from_path_deep_nested
      result = Vident::Component.stimulus_identifier_from_path("admin/settings/user_profile")
      assert_equal "admin--settings--user-profile", result
    end

    # Test instance methods
    def test_before_initialize_hook
      test_class = Class.new do
        include Vident::Component

        def before_initialize(attrs)
          @before_initialize_called = true
        end

        def before_initialize_called?
          @before_initialize_called
        end

        def attribute(name)
          nil
        end

        def to_h
          {}
        end

        def helpers
          TestHelpers.new
        end

        def root
          TestRoot.new
        end

        def produce_style_classes(classes)
          ""
        end
      end

      component = test_class.new
      assert component.before_initialize_called?
    end

    def test_after_initialize_hook
      test_class = Class.new do
        include Vident::Component

        def after_initialize
          @after_initialize_called = true
        end

        def after_initialize_called?
          @after_initialize_called
        end

        def attribute(name)
          nil
        end

        def to_h
          {}
        end

        def helpers
          TestHelpers.new
        end

        def root
          TestRoot.new
        end

        def produce_style_classes(classes)
          ""
        end
      end

      component = test_class.new
      assert component.after_initialize_called?
    end

    def test_clone_with_no_overrides
      cloned = @component.clone
      assert_instance_of @test_component_class, cloned
      refute_same @component, cloned
    end

    def test_inspect_default
      result = @component.inspect
      assert_includes result, "TestComponent"
      assert_includes result, "Vident::Component"
      assert_includes result, "name=\"test\""
      assert_includes result, "value=42"
    end

    def test_inspect_custom_class_name
      result = @component.inspect("CustomType")
      assert_includes result, "TestComponent"
      assert_includes result, "Vident::CustomType"
    end

    def test_id_generates_random_when_nil
      @component.instance_variable_set(:@id, nil)
      id1 = @component.id
      id2 = @component.id

      assert_equal id1, id2  # Should be memoized
      assert_match(/test-component-/, id1)
    end

    def test_id_returns_set_value
      @component.instance_variable_set(:@id, "custom-id")
      assert_equal "custom-id", @component.id
    end

    def test_outlet_id
      @component.instance_variable_set(:@id, "test-id")
      expected = ["test-component", "#test-id"]
      assert_equal expected, @component.outlet_id
    end

    def test_outlet_id_memoized
      id1 = @component.outlet_id
      id2 = @component.outlet_id
      assert_same id1, id2
    end

    def test_stimulus_identifier_instance_method
      assert_equal "test-component", @component.stimulus_identifier
    end

    def test_component_class_name_instance_method
      assert_equal "test-component", @component.component_class_name
    end

    def test_js_event_name_prefix_instance_method
      assert_equal "test-component", @component.js_event_name_prefix
    end

    def test_element_classes_default_nil
      assert_nil @component.element_classes
    end

    def test_element_classes_can_be_overridden
      test_class = Class.new(@test_component_class) do
        def element_classes
          ["custom-class", "another-class"]
        end
      end

      component = test_class.new
      assert_equal ["custom-class", "another-class"], component.element_classes
    end

    def test_render_classes_basic
      component = create_test_component_with_private_methods.new
      result = component.test_render_classes
      assert_equal "test-component", result
    end

    def test_render_classes_with_element_classes
      component = create_test_component_with_private_methods.new
      component.define_singleton_method(:element_classes) { ["custom-class"] }
      result = component.test_render_classes
      assert_equal "test-component custom-class", result
    end

    def test_render_classes_with_erb_defined_classes
      component = create_test_component_with_private_methods.new
      result = component.test_render_classes(["erb-class"])
      assert_equal "test-component erb-class", result
    end

    def test_render_classes_with_html_options_classes
      component = create_test_component_with_private_methods.new
      component.set_test_html_options(class: "html-option-class")
      result = component.test_render_classes
      assert_equal "test-component html-option-class", result
    end

    def test_render_classes_deduplication
      component = create_test_component_with_private_methods.new
      component.define_singleton_method(:element_classes) { ["test-component", "custom-class"] }
      result = component.test_render_classes(["test-component", "erb-class"])
      assert_equal "test-component custom-class erb-class", result
    end

    def test_render_classes_handles_string_classes
      component = create_test_component_with_private_methods.new
      component.define_singleton_method(:element_classes) { "custom-class another-class" }
      result = component.test_render_classes
      assert_equal "test-component custom-class another-class", result
    end

    def test_render_classes_handles_mixed_array_and_string_classes
      component = create_test_component_with_private_methods.new
      component.define_singleton_method(:element_classes) { ["custom-class", "space separated classes"] }
      result = component.test_render_classes
      assert_equal "test-component custom-class space separated classes", result
    end

    def test_render_classes_removes_blank_classes
      component = create_test_component_with_private_methods.new
      component.define_singleton_method(:element_classes) { ["", nil, "valid-class", "  "] }
      result = component.test_render_classes
      assert_equal "test-component valid-class", result
    end

    def test_default_controller_path
      # Test that default_controller_path calls the class method
      assert_equal "test_component", @component.default_controller_path
    end

    # Test delegation methods
    def test_params_delegation
      assert_equal({}, @component.params)
    end

    def test_action_delegation
      assert_equal "action_result", @component.action
    end

    def test_target_delegation
      assert_equal "target_result", @component.target
    end

    def test_named_classes_delegation
      assert_equal "named_classes_result", @component.named_classes
    end

    # Test complex scenarios
    def test_component_with_nested_namespace
      nested_class = Class.new do
        include Vident::Component

        def self.name
          "Admin::Settings::UserProfile"
        end

        def attribute(name)
          nil
        end

        def to_h
          {}
        end

        def helpers
          TestHelpers.new
        end

        def root
          TestRoot.new
        end

        def produce_style_classes(classes)
          classes.compact.join(" ")
        end
      end

      component = nested_class.new
      assert_equal "admin--settings--user-profile", component.stimulus_identifier
      assert_equal "admin--settings--user-profile", component.component_class_name
    end

    def test_multiple_components_have_different_ids
      component1 = @test_component_class.new
      component2 = @test_component_class.new

      refute_equal component1.id, component2.id
    end

    def test_component_name_memoization
      # Call component_name multiple times
      name1 = @test_component_class.component_name
      name2 = @test_component_class.component_name

      assert_equal name1, name2
      assert_same name1, name2  # Should be the same object (memoized)
    end

    # Test class that exposes private methods for testing
    def create_test_component_with_private_methods
      test_component_class = @test_component_class

      Class.new(test_component_class) do
        # Expose private methods for testing
        def test_render_classes(erb_defined_classes = nil)
          render_classes(erb_defined_classes)
        end

        def test_stimulus_options_for_root_component
          stimulus_options_for_root_component
        end

        def test_stimulus_options_for_component(options)
          stimulus_options_for_component(options)
        end

        def test_prepare_html_options(erb_options)
          prepare_html_options(erb_options)
        end

        def test_prepare_stimulus_option(options, name)
          prepare_stimulus_option(options, name)
        end

        def test_merge_stimulus_option(options, name)
          merge_stimulus_option(options, name)
        end

        def test_root_element_attributes
          root_element_attributes
        end

        def test_random_id
          random_id
        end

        def test_dedupe_view_component_classes(html_classes)
          dedupe_view_component_classes(html_classes)
        end

        # Override attribute method to return test data
        def attribute(name)
          case name
          when :html_options
            @test_html_options || {}
          when :actions, :targets, :controllers, :outlets, :values
            @test_attributes ||= {}
            @test_attributes[name] || []
          when :named_classes
            @test_attributes ||= {}
            @test_attributes[name] || {}
          when :id
            @test_id
          when :element_tag
            @test_element_tag
          when :outlet_host
            @test_outlet_host
          end
        end

        # Test helper methods
        def set_test_attribute(name, value)
          @test_attributes ||= {}
          @test_attributes[name] = value
        end

        def set_test_html_options(options)
          @test_html_options = options
        end

        def set_test_id(id)
          @test_id = id
        end

        def set_test_element_tag(tag)
          @test_element_tag = tag
        end

        def set_test_outlet_host(host)
          @test_outlet_host = host
        end

        def set_pending_actions(actions)
          @pending_actions = actions
        end

        def set_pending_targets(targets)
          @pending_targets = targets
        end

        def set_pending_named_classes(classes)
          @pending_named_classes = classes
        end
      end
    end

    # Tests for private methods through public interface
    def test_private_render_classes_basic
      component = create_test_component_with_private_methods.new
      result = component.test_render_classes
      assert_equal "test-component", result
    end

    def test_private_render_classes_with_erb_classes
      component = create_test_component_with_private_methods.new
      result = component.test_render_classes(["erb-class"])
      assert_equal "test-component erb-class", result
    end

    def test_private_render_classes_with_html_options
      component = create_test_component_with_private_methods.new
      component.set_test_html_options(class: "html-class")
      result = component.test_render_classes
      assert_equal "test-component html-class", result
    end

    def test_private_stimulus_options_for_component_basic
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:actions, [])
      component.set_test_attribute(:targets, [])
      component.set_test_attribute(:controllers, [])
      component.set_test_attribute(:outlets, [])
      component.set_test_attribute(:named_classes, {})

      options = {}
      result = component.test_stimulus_options_for_component(options)

      assert result.key?(:id)
      assert_equal :div, result[:element_tag]
      assert result.key?(:html_options)
      assert_equal ["test_component"], result[:controllers]  # Default controller path
      assert_equal [], result[:actions]
      assert_equal [], result[:targets]
      assert_equal [], result[:outlets]
      assert_equal({}, result[:named_classes])
      assert result.key?(:values)
    end

    def test_private_stimulus_options_for_component_with_pending_actions
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:actions, ["existing"])
      component.set_test_attribute(:targets, [])
      component.set_test_attribute(:controllers, [])
      component.set_test_attribute(:outlets, [])
      component.set_test_attribute(:named_classes, {})
      component.set_pending_actions(["pending"])

      options = {actions: ["option"]}
      result = component.test_stimulus_options_for_component(options)

      assert_equal ["existing", "option", "pending"], result[:actions]
    end

    def test_private_stimulus_options_for_component_with_pending_targets
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:actions, [])
      component.set_test_attribute(:targets, ["existing"])
      component.set_test_attribute(:controllers, [])
      component.set_test_attribute(:outlets, [])
      component.set_test_attribute(:named_classes, {})
      component.set_pending_targets(["pending"])

      options = {targets: ["option"]}
      result = component.test_stimulus_options_for_component(options)

      assert_equal ["existing", "option", "pending"], result[:targets]
    end

    def test_private_stimulus_options_for_component_with_pending_named_classes
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:actions, [])
      component.set_test_attribute(:targets, [])
      component.set_test_attribute(:controllers, [])
      component.set_test_attribute(:outlets, [])
      component.set_test_attribute(:named_classes, {existing: "class"})
      component.set_pending_named_classes({pending: "pending-class"})

      options = {named_classes: {option: "option-class"}}
      result = component.test_stimulus_options_for_component(options)

      expected = {existing: "class", option: "option-class", pending: "pending-class"}
      assert_equal expected, result[:named_classes]
    end

    def test_private_prepare_html_options_basic
      component = create_test_component_with_private_methods.new
      erb_options = {id: "test-id", class: "erb-class"}

      result = component.test_prepare_html_options(erb_options)

      assert_equal "test-id", result[:id]
      assert_equal "test-component erb-class", result[:class]
    end

    def test_private_prepare_html_options_with_component_html_options
      component = create_test_component_with_private_methods.new
      component.set_test_html_options(data: {controller: "test"}, class: "component-class")
      erb_options = {class: "erb-class"}

      result = component.test_prepare_html_options(erb_options)

      assert_equal "test", result[:data][:controller]
      assert_equal "test-component erb-class component-class", result[:class]  # erb class and component class both included
    end

    def test_private_prepare_stimulus_option_with_method
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:values, ["attribute_value"])

      # Define a method on the component
      component.define_singleton_method(:values) { ["method_value"] }

      options = {values: ["option_value"]}
      result = component.test_prepare_stimulus_option(options, :values)

      assert_equal ["method_value", "attribute_value", "option_value"], result
    end

    def test_private_prepare_stimulus_option_without_method
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:values, ["attribute_value"])

      options = {values: ["option_value"]}
      result = component.test_prepare_stimulus_option(options, :values)

      assert_equal ["attribute_value", "option_value"], result
    end

    def test_private_merge_stimulus_option
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:named_classes, {existing: "existing-class"})

      options = {named_classes: {new: "new-class"}}
      result = component.test_merge_stimulus_option(options, :named_classes)

      expected = {existing: "existing-class", new: "new-class"}
      assert_equal expected, result
    end

    def test_private_merge_stimulus_option_with_nil_attribute
      component = create_test_component_with_private_methods.new
      component.set_test_attribute(:named_classes, nil)

      options = {named_classes: {new: "new-class"}}
      result = component.test_merge_stimulus_option(options, :named_classes)

      expected = {new: "new-class"}
      assert_equal expected, result
    end

    def test_private_root_element_attributes_default
      component = create_test_component_with_private_methods.new
      result = component.test_root_element_attributes
      assert_equal({}, result)
    end

    def test_private_random_id_generation
      component = create_test_component_with_private_methods.new
      id1 = component.test_random_id
      id2 = component.test_random_id

      assert_equal id1, id2  # Should be memoized
      assert_match(/test-component-/, id1)
    end

    def test_private_dedupe_view_component_classes_basic
      component = create_test_component_with_private_methods.new
      classes = ["class1", "class2", "class1"]
      result = component.test_dedupe_view_component_classes(classes)

      assert_equal "class1 class2", result
    end

    def test_private_dedupe_view_component_classes_with_spaces
      component = create_test_component_with_private_methods.new
      classes = ["class1 class2", "class3", "class1"]
      result = component.test_dedupe_view_component_classes(classes)

      assert_equal "class1 class2 class3", result
    end

    def test_private_dedupe_view_component_classes_with_blanks
      component = create_test_component_with_private_methods.new
      classes = ["class1", "", nil, "  ", "class2"]
      result = component.test_dedupe_view_component_classes(classes)

      assert_equal "class1 class2", result
    end

    def test_private_dedupe_view_component_classes_empty_result
      component = create_test_component_with_private_methods.new
      classes = ["", nil, "  "]
      result = component.test_dedupe_view_component_classes(classes)

      assert_nil result
    end


    def test_action
      assert_equal "foo--my-controller#myAction", @root_component.action(:my_action)
      assert_equal "click->foo--my-controller#myAction", @root_component.action(:click, :my_action)
      assert_equal "path--to--controller#myAction", @root_component.action("path/to/controller", :my_action)
      assert_equal "hover->path--to--controller#myAction", @root_component.action(:hover, "path/to/controller", :my_action)
    end

    def test_stimulus_action
      stimulus_action = @root_component.stimulus_action(:my_action)
      assert_instance_of Vident::StimulusAction, stimulus_action
      assert_equal "foo--my-controller#myAction", stimulus_action.to_s
      assert_equal "foo--my-controller", stimulus_action.controller
      assert_equal "myAction", stimulus_action.action
      assert_nil stimulus_action.event

      stimulus_action_with_event = @root_component.stimulus_action(:click, :my_action)
      assert_instance_of Vident::StimulusAction, stimulus_action_with_event
      assert_equal "click->foo--my-controller#myAction", stimulus_action_with_event.to_s
      assert_equal "click", stimulus_action_with_event.event
    end

    def test_target
      assert_equal({controller: "foo--my-controller", name: "myTarget"}, @root_component.target(:my_target))
      assert_equal({controller: "path--to--controller", name: "myTarget"}, @root_component.target("path/to/controller", :my_target))
    end

    def test_stimulus_target
      stimulus_target = @root_component.stimulus_target(:my_target)
      assert_instance_of Vident::StimulusTarget, stimulus_target
      assert_equal "foo--my-controller-target", stimulus_target.to_s
      assert_equal "foo--my-controller", stimulus_target.controller
      assert_equal "myTarget", stimulus_target.name
      assert_equal({controller: "foo--my-controller", name: "myTarget"}, stimulus_target.to_h)

      stimulus_target_with_controller = @root_component.stimulus_target("path/to/controller", :my_target)
      assert_instance_of Vident::StimulusTarget, stimulus_target_with_controller
      assert_equal "path--to--controller-target", stimulus_target_with_controller.to_s
      assert_equal "path--to--controller", stimulus_target_with_controller.controller
      assert_equal "myTarget", stimulus_target_with_controller.name
    end

    def test_named_classes
      root = @component.new(stimulus_controllers: ["foo/my_controller"], stimulus_classes: {my_class: "my-class"})
      assert_equal "my-class", root.named_classes(:my_class)
    end

    def test_action_data_attribute
      assert_equal({action: "foo--my-controller#myAction"}, @root_component.action_data_attribute(:my_action))
      assert_equal({action: "click->foo--my-controller#myAction"}, @root_component.action_data_attribute([:click, :my_action]))
    end

    def test_target_data_attribute
      assert_equal({"foo--my-controller-target": "myTarget"}, @root_component.target_data_attribute(:my_target))
    end

    def test_with_controllers
      assert_equal 'data-controller="foo--my-controller"', @root_component.with_controllers("foo/my_controller")
    end

    def test_as_targets
      assert_equal 'data-foo--my-controller-target="myTarget"', @root_component.as_targets(:my_target)
    end

    def test_with_actions
      assert_equal "data-action='foo--my-controller#myAction'", @root_component.with_actions(:my_action)
    end

    def test_outlet_selector_when_no_id
      root_component = @component.new(stimulus_controllers: ["foo/my_controller"], id: "the-id")
      assert_equal "data-foo--my-controller-my-outlet-outlet=\"#the-id [data-controller~=my-outlet]\"", root_component.with_outlets(:my_outlet)
    end

    def test_with_outlets_no_id
      assert_equal "data-foo--my-controller-my-outlet-outlet=\"[data-controller~=my-outlet]\"", @root_component.with_outlets(:my_outlet)
    end

    def test_get_all_data_attrs
      root_component = @component.new(
        id: "the-id",
        stimulus_controllers: ["foo/my_controller"],
        stimulus_classes: {my_class: "my-class"},
        stimulus_outlets: ["my-outlet", ["other-component", ".custom-selector"]],
        stimulus_values: [{my_key: "my-value"}],
        stimulus_actions: [:my_action],
        stimulus_targets: [:my_target]
      )

      # Expected result
      expected_result = {
        controller: "foo--my-controller",
        action: "foo--my-controller#myAction",
        "foo--my-controller-target": "myTarget",
        "foo--my-controller-my-outlet-outlet": "#the-id [data-controller~=my-outlet]",
        "foo--my-controller-other-component-outlet": ".custom-selector",
        "foo--my-controller-my-class-class": "my-class",
        "foo--my-controller-my-key-value": "my-value"
      }

      # Test
      assert_equal expected_result, root_component.get_all_data_attrs
    end
  end
end
