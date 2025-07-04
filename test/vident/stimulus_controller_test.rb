require "test_helper"

module Vident
  class StimulusControllerTest < Minitest::Test
    def setup
      @implied_controller_path = "foo/my_controller"
    end

    def test_single_controller_path
      controller = StimulusController.new("my_controller", implied_controller: @implied_controller_path)
      assert_equal "my-controller", controller.to_s
      assert_equal "my_controller", controller.path
      assert_equal "my-controller", controller.name
      assert_equal "controller", controller.data_attribute_name
      assert_equal "my-controller", controller.data_attribute_value
    end

    def test_nested_controller_path
      controller = StimulusController.new("path/to/my_controller", implied_controller: @implied_controller_path)
      assert_equal "path--to--my-controller", controller.to_s
      assert_equal "path/to/my_controller", controller.path
      assert_equal "path--to--my-controller", controller.name
    end

    def test_controller_with_underscores
      controller = StimulusController.new("my_special_controller", implied_controller: @implied_controller_path)
      assert_equal "my-special-controller", controller.to_s
      assert_equal "my_special_controller", controller.path
      assert_equal "my-special-controller", controller.name
    end

    def test_to_h
      controller = StimulusController.new("my_controller", implied_controller: @implied_controller_path)
      expected_hash = {"controller" => "my-controller"}
      assert_equal expected_hash, controller.to_h
    end

    def test_inspect
      controller = StimulusController.new("my_controller", implied_controller: @implied_controller_path)
      assert_equal '#<Vident::StimulusController {"controller" => "my-controller"}>', controller.inspect
    end

    def test_admin_namespaced_controller
      controller = StimulusController.new("admin/users_controller", implied_controller: @implied_controller_path)
      assert_equal "admin--users-controller", controller.to_s
      assert_equal "admin/users_controller", controller.path
      assert_equal "admin--users-controller", controller.name
    end

    def test_deeply_nested_controller
      controller = StimulusController.new("admin/reports/analytics_controller", implied_controller: @implied_controller_path)
      assert_equal "admin--reports--analytics-controller", controller.to_s
      assert_equal "admin/reports/analytics_controller", controller.path
      assert_equal "admin--reports--analytics-controller", controller.name
    end

    def test_no_arguments_uses_implied_controller
      controller = StimulusController.new(implied_controller: @implied_controller_path)
      assert_equal "foo--my-controller", controller.to_s
      assert_equal @implied_controller_path, controller.path
      assert_equal "foo--my-controller", controller.name
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusController.new("first", "second", implied_controller: @implied_controller_path)
      end

      assert_raises(ArgumentError) do
        StimulusController.new("first", "second", "third", implied_controller: @implied_controller_path)
      end
    end
  end
end
