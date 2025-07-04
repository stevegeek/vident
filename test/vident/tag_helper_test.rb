# frozen_string_literal: true

require "test_helper"

class TagHelperTest < Minitest::Test
  def test_tag_with_stimulus_controllers
    test_class = Class.new do
      include Vident::TagHelper

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

      def generate_tag(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new
    result = component.tag("div", stimulus_controllers: ["test-controller"])
    assert_equal "div", result[:tag]
    assert_instance_of Hash, result[:stimulus]
    assert_instance_of Hash, result[:options]
  end

  def test_tag_with_single_stimulus_controller
    test_class = Class.new do
      include Vident::TagHelper

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

      def generate_tag(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new
    result = component.tag("div", stimulus_controller: "test-controller")
    assert_equal "div", result[:tag]
  end

  def test_tag_attribute_must_be_collection_validation
    test_class = Class.new do
      include Vident::TagHelper

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

      def generate_tag(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new

    # Test with invalid stimulus_controllers (should be enumerable)
    error = assert_raises(ArgumentError) do
      component.tag("div", stimulus_controllers: "invalid")
    end
    assert_includes error.message, "stimulus_controllers"
    assert_includes error.message, "must be an enumerable"
  end

  def test_tag_with_simple_stimulus_attributes
    test_class = Class.new do
      include Vident::TagHelper

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

      def generate_tag(tag_name, stimulus_data_attributes, options, &block)
        {tag: tag_name, stimulus: stimulus_data_attributes, options: options}
      end
    end

    component = test_class.new
    result = component.tag("div", stimulus_controllers: ["test-controller"])

    assert_equal "div", result[:tag]
    assert_instance_of Hash, result[:stimulus]
  end

  def test_tag_wrap_single_stimulus_attribute
    test_class = Class.new do
      include Vident::TagHelper

      def self.name
        "TestComponent"
      end
    end

    component = test_class.new

    # Test with plural only
    result = component.send(:tag_wrap_single_stimulus_attribute, ["item1", "item2"], nil)
    assert_equal ["item1", "item2"], result

    # Test with singular only
    result = component.send(:tag_wrap_single_stimulus_attribute, nil, "item")
    assert_equal ["item"], result

    # Test with both nil
    result = component.send(:tag_wrap_single_stimulus_attribute, nil, nil)
    assert_nil result
  end

  def test_generate_tag_not_implemented
    test_class = Class.new do
      include Vident::TagHelper

      def self.name
        "TestComponent"
      end
    end

    component = test_class.new

    assert_raises(NoMethodError) do
      component.send(:generate_tag, "div", {}, {})
    end
  end
end
