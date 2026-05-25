# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  # A component class (or instance) may stand in for a controller-path String
  # anywhere the cross-controller parser forms accept one. The component
  # supplies its own identifier, so references stay refactor-safe.
  class CrossControllerParsingTest < Minitest::Test
    # Stands in for a Vident component class: responds to the two identifier
    # methods every component exposes via Capabilities::Identifiable.
    ChildComponent = Class.new do
      def self.stimulus_identifier = "admin--widget"

      def self.stimulus_identifier_path = "admin/widget"
    end

    def setup
      @implied = Vident::Stimulus::Controller.new(path: "foo/panel", name: "foo--panel")
    end

    def test_controller_parse_accepts_component_class
      c = Vident::Stimulus::Controller.parse(ChildComponent, implied: @implied)
      assert_equal "admin/widget", c.path
      assert_equal "admin--widget", c.name
    end

    def test_target_parse_accepts_component_class
      t = Vident::Stimulus::Target.parse(ChildComponent, :summary, implied: @implied)
      assert_equal({"admin--widget-target": "summary"}, t.to_h)
    end

    def test_action_parse_accepts_component_class_without_event
      a = Vident::Stimulus::Action.parse(ChildComponent, :toggle, implied: @implied)
      assert_equal "admin--widget#toggle", a.to_s
    end

    def test_action_parse_accepts_component_class_with_event
      a = Vident::Stimulus::Action.parse(:click, ChildComponent, :toggle, implied: @implied)
      assert_equal "click->admin--widget#toggle", a.to_s
    end

    def test_value_parse_accepts_component_class
      v = Vident::Stimulus::Value.parse(ChildComponent, :open, false, implied: @implied)
      assert_equal({"admin--widget-open-value": "false"}, v.to_h)
    end

    def test_param_parse_accepts_component_class
      p = Vident::Stimulus::Param.parse(ChildComponent, :row_id, 7, implied: @implied)
      assert_equal({"admin--widget-row-id-param": "7"}, p.to_h)
    end

    def test_class_map_parse_accepts_component_class
      cm = Vident::Stimulus::ClassMap.parse(ChildComponent, :busy, "opacity-50", implied: @implied)
      assert_equal({"admin--widget-busy-class": "opacity-50"}, cm.to_h)
    end

    def test_outlet_parse_accepts_component_class_as_parent_controller
      o = Vident::Stimulus::Outlet.parse(ChildComponent, :item, implied: @implied)
      assert_equal :"admin--widget-item-outlet", o.data_attribute_key
    end

    def test_string_path_still_stimulizes
      t = Vident::Stimulus::Target.parse("admin/widget", :summary, implied: @implied)
      assert_equal({"admin--widget-target": "summary"}, t.to_h)
    end
  end
end
