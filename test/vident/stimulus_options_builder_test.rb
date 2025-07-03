require "test_helper"

module Vident
  class StimulusOptionsBuilderTest < Minitest::Test
    def setup
      @component = create_mock_component
      @builder = StimulusOptionsBuilder.new(@component)
    end

    def test_build_with_empty_options
      result = @builder.build
      
      assert_equal "test-component-123", result[:id]
      assert_equal :div, result[:element_tag]
      assert_equal ["test/component"], result[:controllers]
      assert_equal [], result[:actions]
      assert_equal [], result[:targets]
      assert_equal [], result[:outlets]
      assert_nil result[:outlet_host]
      assert_equal({}, result[:named_classes])
      assert_equal [], result[:values]
    end

    def test_build_with_options
      options = {
        id: "custom-id",
        element_tag: :span,
        controllers: ["custom-controller"],
        actions: ["click->test#action"],
        targets: ["customTarget"],
        outlets: ["custom-outlet"],
        classes: {loading: "spinner"},
        values: [{url: "https://example.com"}]
      }
      
      result = @builder.build(options)
      
      # The component's id method takes precedence over the options[:id]
      assert_equal "test-component-123", result[:id]
      assert_equal :span, result[:element_tag]
      assert_equal ["test/component", "custom-controller"], result[:controllers]
      assert_equal ["click->test#action"], result[:actions]
      assert_equal ["customTarget"], result[:targets]
      assert_equal ["custom-outlet"], result[:outlets]
      assert_equal({loading: "spinner"}, result[:named_classes])
      assert_equal [{url: "https://example.com"}], result[:values]
    end

    def test_build_with_pending_actions
      result = @builder.build({}, pending_actions: ["pending-action"])
      
      assert_equal ["pending-action"], result[:actions]
    end

    def test_build_with_pending_targets
      result = @builder.build({}, pending_targets: ["pending-target"])
      
      assert_equal ["pending-target"], result[:targets]
    end

    def test_build_with_pending_named_classes
      result = @builder.build({}, pending_named_classes: {error: "alert"})
      
      assert_equal({error: "alert"}, result[:named_classes])
    end

    def test_build_with_html_options
      options = {
        html_options: {
          class: "custom-class",
          data: {test: "value"}
        }
      }
      
      result = @builder.build(options)
      
      # The component's render_classes method combines component classes with erb classes
      assert_equal "test-component custom-class", result[:html_options][:class]
      assert_equal({test: "value"}, result[:html_options][:data])
    end

    def test_build_without_stimulus_controller
      @component.class.instance_variable_set(:@no_stimulus_controller, true)
      
      result = @builder.build
      
      assert_equal [], result[:controllers]
    end

    private

    def create_mock_component
      component_class = Class.new do
        def self.stimulus_controller?
          !@no_stimulus_controller
        end

        def attribute(name)
          case name
          when :stimulus_actions then []
          when :stimulus_targets then []
          when :stimulus_outlets then []
          when :stimulus_outlet_host then nil
          when :stimulus_classes then {}
          when :stimulus_values then []
          when :element_tag then :div
          when :id then nil
          when :html_options then {}
          when :stimulus_controllers then []
          else
            nil
          end
        end

        def id
          "test-component-123"
        end

        def default_controller_path
          "test/component"
        end

        def render_classes(erb_defined_classes = nil)
          classes = ["test-component"]
          classes.concat(Array.wrap(erb_defined_classes)) if erb_defined_classes
          classes.join(" ")
        end

        def respond_to?(method_name, include_private = false)
          [:id, :attribute, :default_controller_path, :render_classes].include?(method_name) || super
        end
      end

      component_class.new
    end
  end
end