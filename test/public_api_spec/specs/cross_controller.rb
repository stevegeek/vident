# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # A parent component emitting Stimulus data attributes bound to a *child*
    # component's controller, without hard-coding the child's identifier
    # string. Two forms: reusing the child's class-level value objects, and
    # naming the child class directly in a parser's controller slot.
    module CrossController
      def cross_child_class
        define_component(name: "RowComponent") do
          stimulus do
            targets :summary
            actions :toggle
            values open: false
          end
        end
      end

      def cross_parent(child, &body)
        klass = define_component(name: "PanelComponent")
        if klass.ancestors.include?(::Phlex::HTML)
          klass.define_method(:view_template) { instance_exec(child, &body) }
        else
          klass.define_method(:call) { instance_exec(child, &body) }
        end
        klass
      end

      # ---- reusing the child's class-level value objects -----------------

      def test_child_class_level_controller_object_reused
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:div, stimulus_controllers: [row.stimulus_controller]) }
        end
        assert_match(/data-controller="[^"]*\brow-component\b/, render(parent.new))
      end

      def test_child_class_level_target_object_reused
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:button, stimulus_target: row.stimulus_target(:summary)) }
        end
        assert_match(/data-row-component-target="summary"/, render(parent.new))
      end

      def test_child_class_level_action_object_reused
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:button, stimulus_action: row.stimulus_action(:click, :toggle)) }
        end
        assert_match(/data-action="click->row-component#toggle"/, render(parent.new))
      end

      def test_child_class_level_value_object_reused
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:div, stimulus_values: [row.stimulus_value(:open, false)]) }
        end
        assert_match(/data-row-component-open-value="false"/, render(parent.new))
      end

      # ---- naming the child class directly in a controller slot ----------

      def test_child_class_as_controller_in_plural
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:div, stimulus_controllers: [row]) }
        end
        assert_match(/data-controller="[^"]*\brow-component\b/, render(parent.new))
      end

      def test_child_class_in_target_tuple
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:button, stimulus_target: [row, :summary]) }
        end
        assert_match(/data-row-component-target="summary"/, render(parent.new))
      end

      def test_child_class_in_action_tuple
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:button, stimulus_action: [:click, row, :toggle]) }
        end
        assert_match(/data-action="click->row-component#toggle"/, render(parent.new))
      end

      def test_child_class_in_value_tuple
        child = cross_child_class
        parent = cross_parent(child) do |row|
          root_element { child_element(:div, stimulus_values: [[row, :open, false]]) }
        end
        assert_match(/data-row-component-open-value="false"/, render(parent.new))
      end
    end
  end
end
