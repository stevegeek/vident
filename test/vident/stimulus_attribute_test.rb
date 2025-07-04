require "test_helper"

module Vident
  class StimulusAttributeTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
      @implied_controller = StimulusController.new(implied_controller: @implied_controller_path)
    end

    def test_cannot_call_abstract_methods_on_base_class
      # Base class cannot be instantiated because parse_arguments is abstract
      assert_raises(NotImplementedError) do
        StimulusAttributeBase.new(implied_controller: @implied_controller)
      end
    end

    def test_shared_methods_available_to_subclasses
      # Test through StimulusAction which inherits from StimulusAttributeBase
      action = StimulusAction.new(:my_action, implied_controller: @implied_controller)

      # These methods should be available from the base class
      assert_respond_to action, :implied_controller_name
      assert_equal "foo--my-controller", action.implied_controller_name
    end

    def test_inspect_method_inherited
      action = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)

      # Both should have inspect method from base class showing to_h
      assert_equal '#<Vident::StimulusAction {"action" => "foo--my-controller#myAction"}>', action.inspect
      assert_equal '#<Vident::StimulusTarget {"foo--my-controller-target" => "myTarget"}>', target.inspect
    end

    def test_to_h_method_inherited
      action = StimulusAction.new(:my_action, implied_controller: @implied_controller)
      target = StimulusTarget.new(:my_target, implied_controller: @implied_controller)

      # Both should implement to_h method
      assert_equal({"action" => "foo--my-controller#myAction"}, action.to_h)
      assert_equal({"foo--my-controller-target" => "myTarget"}, target.to_h)
    end
  end
end
