# frozen_string_literal: true

require "test_helper"

class ChildElementHelperTest < Minitest::Test
  def test_child_element_with_stimulus_controllers
    test_class = Class.new do
      include Vident::ChildElementHelper

      def self.name
        "TestComponent"
      end

      def stimulus_controllers(*controllers)
        Vident::StimulusControllerCollection.new(controllers)
      end

      def stimulus_targets(*targets)
        Vident::StimulusTargetCollection.new(targets)
      end

      def stimulus_actions(*actions)
        Vident::StimulusActionCollection.new(actions)
      end

      def stimulus_outlets(*outlets)
        Vident::StimulusOutletCollection.new(outlets)
      end

      def stimulus_values(values)
        Vident::StimulusValueCollection.new(values)
      end

      def stimulus_classes(classes)
        Vident::StimulusClassCollection.new(classes)
      end

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new
    result = component.child_element("div", stimulus_controllers: ["test-controller"])
    assert_equal "div", result[:tag]
    assert_instance_of Hash, result[:stimulus]
    assert_instance_of Hash, result[:options]
  end

  def test_child_element_with_single_stimulus_controller
    test_class = Class.new do
      include Vident::ChildElementHelper

      def self.name
        "TestComponent"
      end

      def stimulus_controllers(*controllers)
        Vident::StimulusControllerCollection.new(controllers)
      end

      def stimulus_targets(*targets)
        Vident::StimulusTargetCollection.new(targets)
      end

      def stimulus_actions(*actions)
        Vident::StimulusActionCollection.new(actions)
      end

      def stimulus_outlets(*outlets)
        Vident::StimulusOutletCollection.new(outlets)
      end

      def stimulus_values(values)
        Vident::StimulusValueCollection.new(values)
      end

      def stimulus_classes(classes)
        Vident::StimulusClassCollection.new(classes)
      end

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new
    result = component.child_element("div", stimulus_controller: "test-controller")
    assert_equal "div", result[:tag]
  end

  def test_child_element_attribute_must_be_collection_validation
    test_class = Class.new do
      include Vident::ChildElementHelper

      def self.name
        "TestComponent"
      end

      def stimulus_controllers(*controllers)
        Vident::StimulusControllerCollection.new(controllers)
      end

      def stimulus_targets(*targets)
        Vident::StimulusTargetCollection.new(targets)
      end

      def stimulus_actions(*actions)
        Vident::StimulusActionCollection.new(actions)
      end

      def stimulus_outlets(*outlets)
        Vident::StimulusOutletCollection.new(outlets)
      end

      def stimulus_values(values)
        Vident::StimulusValueCollection.new(values)
      end

      def stimulus_classes(classes)
        Vident::StimulusClassCollection.new(classes)
      end

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new

    error = assert_raises(ArgumentError) do
      component.child_element("div", stimulus_controllers: "invalid")
    end
    assert_includes error.message, "stimulus_controllers"
    assert_includes error.message, "must be an enumerable"
  end

  def test_child_element_with_simple_stimulus_attributes
    test_class = Class.new do
      include Vident::ChildElementHelper

      def self.name
        "TestComponent"
      end

      def stimulus_controllers(*controllers)
        Vident::StimulusControllerCollection.new(controllers)
      end

      def stimulus_targets(*targets)
        Vident::StimulusTargetCollection.new(targets)
      end

      def stimulus_actions(*actions)
        Vident::StimulusActionCollection.new(actions)
      end

      def stimulus_outlets(*outlets)
        Vident::StimulusOutletCollection.new(outlets)
      end

      def stimulus_values(values)
        Vident::StimulusValueCollection.new([])
      end

      def stimulus_classes(classes)
        Vident::StimulusClassCollection.new([])
      end

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new
    result = component.child_element("div", stimulus_controllers: ["test-controller"])

    assert_equal "div", result[:tag]
    assert_instance_of Hash, result[:stimulus]
  end

  def test_child_element_wrap_single_stimulus_attribute
    test_class = Class.new do
      include Vident::ChildElementHelper

      def self.name
        "TestComponent"
      end
    end

    component = test_class.new

    result = component.send(:child_element_wrap_single_stimulus_attribute, ["item1", "item2"], nil)
    assert_equal ["item1", "item2"], result

    result = component.send(:child_element_wrap_single_stimulus_attribute, nil, "item")
    assert_equal ["item"], result

    result = component.send(:child_element_wrap_single_stimulus_attribute, nil, nil)
    assert_nil result
  end

  def test_child_element_singular_stimulus_action_preserves_tuple
    captured = {}
    test_class = Class.new do
      include Vident::ChildElementHelper
      define_method(:stimulus_controllers) { |*c| Vident::StimulusControllerCollection.new(c) }
      define_method(:stimulus_targets) { |*| Vident::StimulusTargetCollection.new([]) }
      define_method(:stimulus_actions) do |*actions|
        captured[:actions] = actions
        Vident::StimulusActionCollection.new([])
      end
      define_method(:stimulus_outlets) { |*| Vident::StimulusOutletCollection.new([]) }
      define_method(:stimulus_values) { |_| Vident::StimulusValueCollection.new([]) }
      define_method(:stimulus_classes) { |_| Vident::StimulusClassCollection.new([]) }
      define_method(:generate_child_element) { |*| nil }
    end

    component = test_class.new
    component.child_element(:button, stimulus_action: [:click, :greet])

    assert_equal [[:click, :greet]], captured[:actions]
  end

  def test_child_element_singular_stimulus_target_preserves_tuple
    captured = {}
    test_class = Class.new do
      include Vident::ChildElementHelper
      define_method(:stimulus_controllers) { |*c| Vident::StimulusControllerCollection.new(c) }
      define_method(:stimulus_targets) do |*targets|
        captured[:targets] = targets
        Vident::StimulusTargetCollection.new([])
      end
      define_method(:stimulus_actions) { |*| Vident::StimulusActionCollection.new([]) }
      define_method(:stimulus_outlets) { |*| Vident::StimulusOutletCollection.new([]) }
      define_method(:stimulus_values) { |_| Vident::StimulusValueCollection.new([]) }
      define_method(:stimulus_classes) { |_| Vident::StimulusClassCollection.new([]) }
      define_method(:generate_child_element) { |*| nil }
    end

    component = test_class.new
    component.child_element(:div, stimulus_target: ["path/to/ctrl", :name])

    assert_equal [["path/to/ctrl", :name]], captured[:targets]
  end

  def test_generate_child_element_not_implemented
    test_class = Class.new do
      include Vident::ChildElementHelper

      def self.name
        "TestComponent"
      end
    end

    component = test_class.new

    assert_raises(NoMethodError) do
      component.send(:generate_child_element, "div", {}, {})
    end
  end
end
