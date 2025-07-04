# frozen_string_literal: true

require "test_helper"

class StimulusCollectionMergingTest < Minitest::Test
  def test_controller_collection_merge
    controller1 = Vident::StimulusController.new("controller1")
    controller2 = Vident::StimulusController.new("controller2")

    collection1 = Vident::StimulusControllerCollection.new([controller1])
    collection2 = Vident::StimulusControllerCollection.new([controller2])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusControllerCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
    refute_empty result
  end

  def test_controller_collection_class_merge
    controller1 = Vident::StimulusController.new("controller1")
    controller2 = Vident::StimulusController.new("controller2")

    collection1 = Vident::StimulusControllerCollection.new([controller1])
    collection2 = Vident::StimulusControllerCollection.new([controller2])

    merged = Vident::StimulusControllerCollection.merge(collection1, collection2)
    assert_instance_of Vident::StimulusControllerCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
    refute_empty result
  end

  def test_action_collection_merge
    implied_controller = Vident::StimulusController.new("test")
    action1 = Vident::StimulusAction.new(:click, implied_controller: implied_controller)
    action2 = Vident::StimulusAction.new(:submit, implied_controller: implied_controller)

    collection1 = Vident::StimulusActionCollection.new([action1])
    collection2 = Vident::StimulusActionCollection.new([action2])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusActionCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
    refute_empty result
  end

  def test_action_collection_class_merge
    implied_controller = Vident::StimulusController.new("test")
    action1 = Vident::StimulusAction.new(:click, implied_controller: implied_controller)
    action2 = Vident::StimulusAction.new(:submit, implied_controller: implied_controller)

    collection1 = Vident::StimulusActionCollection.new([action1])
    collection2 = Vident::StimulusActionCollection.new([action2])

    merged = Vident::StimulusActionCollection.merge(collection1, collection2)
    assert_instance_of Vident::StimulusActionCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
    refute_empty result
  end

  def test_target_collection_merge
    implied_controller = Vident::StimulusController.new("test")
    target1 = Vident::StimulusTarget.new(:button, implied_controller: implied_controller)
    target2 = Vident::StimulusTarget.new(:input, implied_controller: implied_controller)

    collection1 = Vident::StimulusTargetCollection.new([target1])
    collection2 = Vident::StimulusTargetCollection.new([target2])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusTargetCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_target_collection_class_merge
    implied_controller = Vident::StimulusController.new("test")
    target1 = Vident::StimulusTarget.new(:button, implied_controller: implied_controller)
    target2 = Vident::StimulusTarget.new(:input, implied_controller: implied_controller)

    collection1 = Vident::StimulusTargetCollection.new([target1])
    collection2 = Vident::StimulusTargetCollection.new([target2])

    merged = Vident::StimulusTargetCollection.merge(collection1, collection2)
    assert_instance_of Vident::StimulusTargetCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_outlet_collection_merge
    implied_controller = Vident::StimulusController.new("test")
    outlet1 = Vident::StimulusOutlet.new(:status, implied_controller: implied_controller, component_id: "test-1")
    outlet2 = Vident::StimulusOutlet.new(:modal, implied_controller: implied_controller, component_id: "test-2")

    collection1 = Vident::StimulusOutletCollection.new([outlet1])
    collection2 = Vident::StimulusOutletCollection.new([outlet2])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusOutletCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_outlet_collection_class_merge
    implied_controller = Vident::StimulusController.new("test")
    outlet1 = Vident::StimulusOutlet.new(:status, implied_controller: implied_controller, component_id: "test-1")
    outlet2 = Vident::StimulusOutlet.new(:modal, implied_controller: implied_controller, component_id: "test-2")

    collection1 = Vident::StimulusOutletCollection.new([outlet1])
    collection2 = Vident::StimulusOutletCollection.new([outlet2])

    merged = Vident::StimulusOutletCollection.merge(collection1, collection2)
    assert_instance_of Vident::StimulusOutletCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_value_collection_merge
    implied_controller = Vident::StimulusController.new("test")
    value1 = Vident::StimulusValue.new(:url, "https://example.com", implied_controller: implied_controller)
    value2 = Vident::StimulusValue.new(:count, 42, implied_controller: implied_controller)

    collection1 = Vident::StimulusValueCollection.new([value1])
    collection2 = Vident::StimulusValueCollection.new([value2])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusValueCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_value_collection_class_merge
    implied_controller = Vident::StimulusController.new("test")
    value1 = Vident::StimulusValue.new(:url, "https://example.com", implied_controller: implied_controller)
    value2 = Vident::StimulusValue.new(:count, 42, implied_controller: implied_controller)

    collection1 = Vident::StimulusValueCollection.new([value1])
    collection2 = Vident::StimulusValueCollection.new([value2])

    merged = Vident::StimulusValueCollection.merge(collection1, collection2)
    assert_instance_of Vident::StimulusValueCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_class_collection_merge
    implied_controller = Vident::StimulusController.new("test")
    class1 = Vident::StimulusClass.new(:loading, "spinner", implied_controller: implied_controller)
    class2 = Vident::StimulusClass.new(:error, "text-red-500", implied_controller: implied_controller)

    collection1 = Vident::StimulusClassCollection.new([class1])
    collection2 = Vident::StimulusClassCollection.new([class2])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusClassCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_class_collection_class_merge
    implied_controller = Vident::StimulusController.new("test")
    class1 = Vident::StimulusClass.new(:loading, "spinner", implied_controller: implied_controller)
    class2 = Vident::StimulusClass.new(:error, "text-red-500", implied_controller: implied_controller)

    collection1 = Vident::StimulusClassCollection.new([class1])
    collection2 = Vident::StimulusClassCollection.new([class2])

    merged = Vident::StimulusClassCollection.merge(collection1, collection2)
    assert_instance_of Vident::StimulusClassCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
  end

  def test_merge_with_empty_collections
    controller1 = Vident::StimulusController.new("controller1")
    collection1 = Vident::StimulusControllerCollection.new([controller1])
    collection2 = Vident::StimulusControllerCollection.new([])

    merged = collection1.merge(collection2)
    assert_instance_of Vident::StimulusControllerCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
    refute_empty result
  end

  def test_merge_multiple_collections
    controller1 = Vident::StimulusController.new("controller1")
    controller2 = Vident::StimulusController.new("controller2")
    controller3 = Vident::StimulusController.new("controller3")

    collection1 = Vident::StimulusControllerCollection.new([controller1])
    collection2 = Vident::StimulusControllerCollection.new([controller2])
    collection3 = Vident::StimulusControllerCollection.new([controller3])

    merged = Vident::StimulusControllerCollection.merge(collection1, collection2, collection3)
    assert_instance_of Vident::StimulusControllerCollection, merged

    result = merged.to_h
    assert_instance_of Hash, result
    refute_empty result
  end
end
