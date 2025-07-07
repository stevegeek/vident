# frozen_string_literal: true

require "test_helper"

class ComponentClassListsTest < Minitest::Test
  def test_render_classes_with_no_extra_classes
    test_class = Class.new do
      include Vident::ComponentClassLists

      def self.name
        "TestComponent"
      end

      def class_list_builder
        @class_list_builder ||= Vident::ClassListBuilder.new(
          tailwind_merger: nil,
          component_name: "test-component",
          element_classes: "base-class",
          additional_classes: nil,
          html_class: nil
        )
      end
    end

    component = test_class.new
    result = component.render_classes
    assert_includes result, "base-class"
  end

  def test_render_classes_with_extra_classes
    test_class = Class.new do
      include Vident::ComponentClassLists

      def self.name
        "TestComponent"
      end

      def class_list_builder
        @class_list_builder ||= Vident::ClassListBuilder.new(
          tailwind_merger: nil,
          component_name: "test-component",
          element_classes: "base-class",
          additional_classes: nil,
          html_class: nil
        )
      end
    end

    component = test_class.new
    result = component.render_classes("extra-class")
    assert_includes result, "base-class"
    assert_includes result, "extra-class"
  end

  def test_class_list_for_stimulus_classes
    test_class = Class.new do
      include Vident::ComponentClassLists

      def self.name
        "TestComponent"
      end

      def initialize
        @stimulus_classes_collection = [
          create_stimulus_class("active", "bg-green-500"),
          create_stimulus_class("inactive", "bg-gray-300")
        ]
      end

      def create_stimulus_class(name, value)
        obj = Object.new
        obj.define_singleton_method(:class_name) { name }
        obj.define_singleton_method(:to_s) { value }
        obj
      end

      def class_list_builder
        @class_list_builder ||= Vident::ClassListBuilder.new(
          tailwind_merger: nil,
          component_name: nil,
          element_classes: nil,
          additional_classes: nil,
          html_class: nil
        )
      end
    end

    component = test_class.new
    result = component.class_list_for_stimulus_classes("active")
    assert_equal "bg-green-500", result
  end

  def test_class_list_for_stimulus_classes_returns_empty_string_when_no_match
    test_class = Class.new do
      include Vident::ComponentClassLists

      def self.name
        "TestComponent"
      end

      def initialize
        @stimulus_classes_collection = []
      end

      def class_list_builder
        @class_list_builder ||= Vident::ClassListBuilder.new(
          tailwind_merger: nil,
          component_name: nil,
          element_classes: nil,
          additional_classes: nil,
          html_class: nil
        )
      end
    end

    component = test_class.new
    result = component.class_list_for_stimulus_classes("nonexistent")
    assert_equal "", result
  end

  def test_class_list_builder_initialization_with_classes
    test_class = Class.new do
      include Vident::ComponentClassLists

      def self.name
        "TestComponent"
      end

      def initialize
        @classes = "custom-class"
        @html_options = {class: "html-class"}
      end

      def tailwind_merger
        nil
      end

      def component_name
        "test-component"
      end

      def element_classes
        "element-class"
      end
    end

    component = test_class.new
    builder = component.send(:class_list_builder)
    assert_instance_of Vident::ClassListBuilder, builder
  end
end
