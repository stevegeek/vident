require "test_helper"

module Vident
  class RootComponentTest < Minitest::Test
    def setup
      component = Class.new do
        include Vident::RootComponent

        def get_all_data_attrs
          tag_data_attributes
        end
      end
      @root_component = component.new(controllers: ["foo/my_controller"])
    end

    def test_action
      assert_equal "foo--my-controller#myAction", @root_component.action(:my_action)
      assert_equal "click->foo--my-controller#myAction", @root_component.action(:click, :my_action)
      assert_equal "path--to--controller#myAction", @root_component.action("path/to/controller", :my_action)
      assert_equal "hover->path--to--controller#myAction", @root_component.action(:hover, "path/to/controller", :my_action)
    end

    def test_target
      assert_equal({controller: "foo--my-controller", name: "myTarget"}, @root_component.target(:my_target))
      assert_equal({controller: "path--to--controller", name: "myTarget"}, @root_component.target("path/to/controller", :my_target))
    end

    def test_named_classes
      @root_component.instance_variable_set(:@named_classes, {my_class: "my-class"})
      assert_equal "my-class", @root_component.named_classes(:my_class)
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

    def test_get_all_data_attrs
      # Setup
      @root_component.instance_variable_set(:@named_classes, {my_class: "my-class"})
      @root_component.instance_variable_set(:@outlets, ["my-outlet", ["other-component", "#my_id"]])
      @root_component.instance_variable_set(:@data_maps, [{my_key: "my-value"}])
      @root_component.instance_variable_set(:@actions, [:my_action])
      @root_component.instance_variable_set(:@targets, [:my_target])

      # Expected result
      expected_result = {
        controller: "foo--my-controller",
        action: "foo--my-controller#myAction",
        "foo--my-controller-target": "myTarget",
        "foo--my-controller-my-outlet-outlet": "[data-controller~=my-outlet]",
        "foo--my-controller-other-component-outlet": "#my_id",
        "foo--my-controller-my-class-class": "my-class",
        "foo--my-controller-my_key": "my-value"
      }

      # Test
      assert_equal expected_result, @root_component.get_all_data_attrs
    end
  end
end
