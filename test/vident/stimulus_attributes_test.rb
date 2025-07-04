# frozen_string_literal: true

require "test_helper"

class StimulusAttributesTest < Minitest::Test
  def setup
    @test_class = Class.new do
      include Vident::StimulusAttributes

      def initialize
        @stimulus_controllers = ["test_controller"]
        @id = "test-id"
      end

      def self.name
        "TestComponent"
      end
    end
    @component = @test_class.new
  end

  def test_stimulus_controller_basic
    result = @component.stimulus_controller("my_controller")
    assert_instance_of Vident::StimulusController, result
  end

  def test_stimulus_controllers_basic
    result = @component.stimulus_controllers("controller1", "controller2")
    assert_instance_of Vident::StimulusControllerCollection, result
  end

  def test_stimulus_controllers_empty
    result = @component.stimulus_controllers
    assert_instance_of Vident::StimulusControllerCollection, result
  end

  def test_stimulus_action_basic
    result = @component.stimulus_action(:click)
    assert_instance_of Vident::StimulusAction, result
  end

  def test_stimulus_actions_basic
    result = @component.stimulus_actions("action1", "action2")
    assert_instance_of Vident::StimulusActionCollection, result
  end

  def test_stimulus_actions_empty
    result = @component.stimulus_actions
    assert_instance_of Vident::StimulusActionCollection, result
  end

  def test_stimulus_target_basic
    result = @component.stimulus_target(:my_target)
    assert_instance_of Vident::StimulusTarget, result
  end

  def test_stimulus_targets_basic
    result = @component.stimulus_targets("target1", "target2")
    assert_instance_of Vident::StimulusTargetCollection, result
  end

  def test_stimulus_targets_empty
    result = @component.stimulus_targets
    assert_instance_of Vident::StimulusTargetCollection, result
  end

  def test_stimulus_outlet_basic
    result = @component.stimulus_outlet(:user_status)
    assert_instance_of Vident::StimulusOutlet, result
  end

  def test_stimulus_outlets_basic
    result = @component.stimulus_outlets("outlet1", "outlet2")
    assert_instance_of Vident::StimulusOutletCollection, result
  end

  def test_stimulus_outlets_empty
    result = @component.stimulus_outlets
    assert_instance_of Vident::StimulusOutletCollection, result
  end

  def test_stimulus_value_basic
    result = @component.stimulus_value(:url, "https://example.com")
    assert_instance_of Vident::StimulusValue, result
  end

  def test_stimulus_values_with_hash
    result = @component.stimulus_values(url: "https://example.com", count: 5)
    assert_instance_of Vident::StimulusValueCollection, result
  end

  def test_stimulus_values_empty
    result = @component.stimulus_values
    assert_instance_of Vident::StimulusValueCollection, result
  end

  def test_stimulus_class_basic
    result = @component.stimulus_class(:loading, "spinner active")
    assert_instance_of Vident::StimulusClass, result
  end

  def test_stimulus_classes_with_hash
    result = @component.stimulus_classes(loading: "spinner active", error: "text-red-500")
    assert_instance_of Vident::StimulusClassCollection, result
  end

  def test_stimulus_classes_empty
    result = @component.stimulus_classes
    assert_instance_of Vident::StimulusClassCollection, result
  end

  def test_add_stimulus_controllers
    @component.add_stimulus_controllers("new_controller")
    collection = @component.instance_variable_get(:@stimulus_controllers_collection)
    assert_instance_of Vident::StimulusControllerCollection, collection
  end

  def test_add_stimulus_actions
    @component.add_stimulus_actions("new_action")
    collection = @component.instance_variable_get(:@stimulus_actions_collection)
    assert_instance_of Vident::StimulusActionCollection, collection
  end

  def test_add_stimulus_targets
    @component.add_stimulus_targets("new_target")
    collection = @component.instance_variable_get(:@stimulus_targets_collection)
    assert_instance_of Vident::StimulusTargetCollection, collection
  end

  def test_add_stimulus_outlets
    @component.add_stimulus_outlets("new_outlet")
    collection = @component.instance_variable_get(:@stimulus_outlets_collection)
    assert_instance_of Vident::StimulusOutletCollection, collection
  end

  def test_add_stimulus_values
    @component.add_stimulus_values(url: "https://example.com")
    collection = @component.instance_variable_get(:@stimulus_values_collection)
    assert_instance_of Vident::StimulusValueCollection, collection
  end

  def test_add_stimulus_classes
    @component.add_stimulus_classes(loading: "spinner active")
    collection = @component.instance_variable_get(:@stimulus_classes_collection)
    assert_instance_of Vident::StimulusClassCollection, collection
  end

  def test_implied_controller_path
    path = @component.send(:implied_controller_path)
    assert_equal "test_controller", path
  end

  def test_implied_controller_path_error_without_controllers
    component = Class.new do
      include Vident::StimulusAttributes

      def initialize
        @stimulus_controllers = []
      end
    end.new

    assert_raises(StandardError) do
      component.send(:implied_controller_path)
    end
  end

  def test_collection_merging
    @component.add_stimulus_controllers("controller1")
    @component.add_stimulus_controllers("controller2")
    collection = @component.instance_variable_get(:@stimulus_controllers_collection)
    assert_instance_of Vident::StimulusControllerCollection, collection
    # Test that merging worked by checking the hash output
    result = collection.to_h
    assert_instance_of Hash, result
    refute_empty result
  end

  def test_stimulus_values_with_complex_input
    result = @component.stimulus_values(
      {url: "https://example.com", count: 5}
    )
    assert_instance_of Vident::StimulusValueCollection, result
  end

  def test_stimulus_classes_with_complex_input
    result = @component.stimulus_classes(
      {loading: "spinner active", error: "text-red-500"}
    )
    assert_instance_of Vident::StimulusClassCollection, result
  end
end
