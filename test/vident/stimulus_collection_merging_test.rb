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

    assert_equal "controller1 controller2 controller3", merged.to_h[:controller]
  end

  # Content-preservation assertions. The rest of this file's tests prove the
  # merged collection has the right *type* and is non-empty; these prove the
  # actual items from both sides survive the merge, so a silent item-drop in
  # StimulusCollectionBase#merge can't pass unnoticed.

  def test_merged_controllers_contain_items_from_both_sides
    c1 = Vident::StimulusController.new("alpha")
    c2 = Vident::StimulusController.new("beta")
    merged = Vident::StimulusControllerCollection.new([c1]).merge(Vident::StimulusControllerCollection.new([c2]))
    assert_equal "alpha beta", merged.to_h[:controller]
  end

  def test_merged_values_contain_items_from_both_sides
    ctrl = Vident::StimulusController.new("foo")
    v1 = Vident::StimulusValue.new(:url, "https://a.test", implied_controller: ctrl)
    v2 = Vident::StimulusValue.new(:count, 7, implied_controller: ctrl)
    merged = Vident::StimulusValueCollection.new([v1]).merge(Vident::StimulusValueCollection.new([v2]))
    h = merged.to_h
    assert_equal "https://a.test", h["foo-url-value"]
    assert_equal "7", h["foo-count-value"]
  end

  def test_merged_actions_contain_items_from_both_sides
    ctrl = Vident::StimulusController.new("foo")
    a1 = Vident::StimulusAction.new(:click, :open, implied_controller: ctrl)
    a2 = Vident::StimulusAction.new(:submit, :save, implied_controller: ctrl)
    merged = Vident::StimulusActionCollection.new([a1]).merge(Vident::StimulusActionCollection.new([a2]))
    assert_equal "click->foo#open submit->foo#save", merged.to_h[:action]
  end

  def test_merged_targets_contain_items_from_both_sides
    ctrl = Vident::StimulusController.new("foo")
    t1 = Vident::StimulusTarget.new(:body, implied_controller: ctrl)
    t2 = Vident::StimulusTarget.new(:footer, implied_controller: ctrl)
    merged = Vident::StimulusTargetCollection.new([t1]).merge(Vident::StimulusTargetCollection.new([t2]))
    # Target names space-join under the single foo-target key.
    assert_equal "body footer", merged.to_h["foo-target"]
  end

  def test_merged_classes_contain_items_from_both_sides
    ctrl = Vident::StimulusController.new("foo")
    c1 = Vident::StimulusClass.new(:loading, "spinner", implied_controller: ctrl)
    c2 = Vident::StimulusClass.new(:error, "text-red-500", implied_controller: ctrl)
    merged = Vident::StimulusClassCollection.new([c1]).merge(Vident::StimulusClassCollection.new([c2]))
    h = merged.to_h
    assert_equal "spinner", h["foo-loading-class"]
    assert_equal "text-red-500", h["foo-error-class"]
  end

  def test_merged_params_contain_items_from_both_sides
    ctrl = Vident::StimulusController.new("foo")
    p1 = Vident::StimulusParam.new(:kind, "promote", implied_controller: ctrl)
    p2 = Vident::StimulusParam.new(:release_id, 1, implied_controller: ctrl)
    merged = Vident::StimulusParamCollection.new([p1]).merge(Vident::StimulusParamCollection.new([p2]))
    h = merged.to_h
    assert_equal "promote", h["foo-kind-param"]
    assert_equal "1", h["foo-release-id-param"]
  end

  def test_merged_outlets_contain_items_from_both_sides
    ctrl = Vident::StimulusController.new("foo")
    o1 = Vident::StimulusOutlet.new(:modal, ".modal", implied_controller: ctrl)
    o2 = Vident::StimulusOutlet.new(:toast, ".toast", implied_controller: ctrl)
    merged = Vident::StimulusOutletCollection.new([o1]).merge(Vident::StimulusOutletCollection.new([o2]))
    h = merged.to_h
    assert_equal ".modal", h["foo-modal-outlet"]
    assert_equal ".toast", h["foo-toast-outlet"]
  end
end
