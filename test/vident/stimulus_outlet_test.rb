require "test_helper"
require "minitest/mock"

module Vident
  class StimulusOutletTest < Minitest::Test
    def setup
      @implied_controller = StimulusController.new("foo/my_controller")
    end

    def test_single_symbol_argument_auto_selector
      outlet = StimulusOutlet.new(:user_status, implied_controller: @implied_controller)
      assert_equal "[data-controller~=user-status]", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "user-status", outlet.outlet_name
      assert_equal "[data-controller~=user-status]", outlet.selector
      assert_equal "foo--my-controller-user-status-outlet", outlet.data_attribute_name
      assert_equal "[data-controller~=user-status]", outlet.data_attribute_value
    end

    def test_single_symbol_argument_with_component_id
      outlet = StimulusOutlet.new(:user_status, implied_controller: @implied_controller, component_id: "chat-widget")
      assert_equal "#chat-widget [data-controller~=user-status]", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "user-status", outlet.outlet_name
      assert_equal "#chat-widget [data-controller~=user-status]", outlet.selector
    end

    def test_single_string_argument_auto_selector
      outlet = StimulusOutlet.new("user-status", implied_controller: @implied_controller)
      assert_equal "[data-controller~=user-status]", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "user-status", outlet.outlet_name
      assert_equal "[data-controller~=user-status]", outlet.selector
    end

    def test_two_arguments_with_symbol_and_string
      outlet = StimulusOutlet.new(:user_status, ".online-user", implied_controller: @implied_controller)
      assert_equal ".online-user", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "user-status", outlet.outlet_name
      assert_equal ".online-user", outlet.selector
      assert_equal "foo--my-controller-user-status-outlet", outlet.data_attribute_name
      assert_equal ".online-user", outlet.data_attribute_value
    end

    def test_single_array_argument
      outlet = StimulusOutlet.new(["user-status", ".online-user"], implied_controller: @implied_controller)
      assert_equal ".online-user", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "user-status", outlet.outlet_name
      assert_equal ".online-user", outlet.selector
    end

    def test_three_arguments_with_controller_path
      outlet = StimulusOutlet.new("path/to/controller", :user_status, ".online-user", implied_controller: @implied_controller)
      assert_equal ".online-user", outlet.to_s
      assert_equal "path--to--controller", outlet.controller
      assert_equal "user-status", outlet.outlet_name
      assert_equal ".online-user", outlet.selector
      assert_equal "path--to--controller-user-status-outlet", outlet.data_attribute_name
      assert_equal ".online-user", outlet.data_attribute_value
    end

    def test_component_with_stimulus_identifier
      mock_component = Object.new
      def mock_component.stimulus_identifier
        "chat--component"
      end

      outlet = StimulusOutlet.new(mock_component, implied_controller: @implied_controller)
      assert_equal "[data-controller~=chat--component]", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "chat--component", outlet.outlet_name
      assert_equal "[data-controller~=chat--component]", outlet.selector
    end

    def test_root_component_with_implied_controller_path
      mock_component = Object.new
      def mock_component.stimulus_identifier
        "chat--widget"
      end

      outlet = StimulusOutlet.new(mock_component, implied_controller: @implied_controller)
      assert_equal "[data-controller~=chat--widget]", outlet.to_s
      assert_equal "foo--my-controller", outlet.controller
      assert_equal "chat--widget", outlet.outlet_name
      assert_equal "[data-controller~=chat--widget]", outlet.selector
    end

    def test_to_h
      outlet = StimulusOutlet.new(:user_status, ".online-user", implied_controller: @implied_controller)
      expected_hash = {"foo--my-controller-user-status-outlet" => ".online-user"}
      assert_equal expected_hash, outlet.to_h
    end

    def test_inspect
      outlet = StimulusOutlet.new(:user_status, ".online-user", implied_controller: @implied_controller)
      assert_equal '#<Vident::StimulusOutlet {"foo--my-controller-user-status-outlet" => ".online-user"}>', outlet.inspect
    end

    def test_invalid_number_of_arguments
      assert_raises(ArgumentError) do
        StimulusOutlet.new(implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusOutlet.new(:a, :b, :c, :d, implied_controller: @implied_controller)
      end
    end

    def test_invalid_argument_types
      assert_raises(ArgumentError) do
        StimulusOutlet.new(123, implied_controller: @implied_controller)
      end

      assert_raises(ArgumentError) do
        StimulusOutlet.new(:outlet_name, 123, implied_controller: @implied_controller)
      end
    end
  end
end
