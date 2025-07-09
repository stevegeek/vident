require "test_helper"

module Vident
  class ComponentTest < Minitest::Test
    def setup
      # Create a test component class that includes Component
      @test_component_class = Class.new do
        include Vident::Component

        def self.name
          "TestComponent"
        end

        # Define a simple root_element method for testing
        def root_element(&block)
          # This is just a stub for testing
        end
      end

      @component = @test_component_class.new
    end

    # Test class methods
    def test_stimulus_identifier_from_path_simple
      result = Vident::StimulusComponent.stimulus_identifier_from_path("my_component")
      assert_equal "my-component", result
    end

    def test_stimulus_identifier_from_path_nested
      result = Vident::StimulusComponent.stimulus_identifier_from_path("admin/user_profile")
      assert_equal "admin--user-profile", result
    end

    def test_stimulus_identifier_from_path_deep_nested
      result = Vident::StimulusComponent.stimulus_identifier_from_path("admin/settings/user_profile")
      assert_equal "admin--settings--user-profile", result
    end

    def test_component_name
      assert_equal "test-component", @test_component_class.component_name
    end

    def test_stimulus_identifier
      expected = "test-component"
      assert_equal expected, @test_component_class.stimulus_identifier
    end

    def test_stimulus_identifier_path
      assert_equal "test_component", @test_component_class.stimulus_identifier_path
    end

    # Test instance methods
    def test_clone_with_no_overrides
      cloned = @component.clone
      assert_instance_of @test_component_class, cloned
      refute_same @component, cloned
    end

    def test_clone_with_overrides
      cloned = @component.clone(id: "new-id")
      assert_equal "new-id", cloned.id
      refute_same @component, cloned
    end

    def test_inspect_default
      result = @component.inspect
      assert_includes result, "TestComponent"
      assert_includes result, "Vident::Component"
    end

    def test_inspect_custom_class_name
      result = @component.inspect("CustomType")
      assert_includes result, "TestComponent"
      assert_includes result, "Vident::CustomType"
    end

    def test_id_generates_random_when_nil
      id1 = @component.id
      id2 = @component.id

      assert_equal id1, id2  # Should be memoized
      assert_match(/test-component-/, id1)
    end

    def test_id_returns_set_value
      component = @test_component_class.new(id: "custom-id")
      assert_equal "custom-id", component.id
    end

    def test_stimulus_identifier_instance_method
      assert_equal "test-component", @component.stimulus_identifier
    end

    def test_component_name_instance_method
      assert_equal "test-component", @component.component_name
    end

    def test_element_classes_default_nil
      assert_nil @component.element_classes
    end

    def test_element_classes_can_be_overridden
      test_class = Class.new(@test_component_class) do
        def element_classes
          ["custom-class", "another-class"]
        end
      end

      component = test_class.new
      assert_equal ["custom-class", "another-class"], component.element_classes
    end

    def test_root_element_attributes_default
      assert_equal({}, @component.root_element_attributes)
    end

    def test_multiple_components_have_different_ids
      component1 = @test_component_class.new
      component2 = @test_component_class.new

      refute_equal component1.id, component2.id
    end

    def test_component_name_memoization
      # Call component_name multiple times
      name1 = @test_component_class.component_name
      name2 = @test_component_class.component_name

      assert_equal name1, name2
      assert_same name1, name2  # Should be the same object (memoized)
    end

    # Test with nested namespace
    def test_component_with_nested_namespace
      nested_class = Class.new do
        include Vident::Component

        def self.name
          "Admin::Settings::UserProfile"
        end

        def root_element(&block)
          # Stub
        end
      end

      component = nested_class.new
      assert_equal "admin--settings--user-profile", component.stimulus_identifier
      assert_equal "admin--settings--user-profile", component.component_name
    end

    def test_after_component_initialize_hook
      called = false
      test_class = Class.new do
        include Vident::Component

        def self.name
          "TestAfterInit"
        end

        define_method(:after_component_initialize) do
          called = true
        end

        def root_element(&block)
          # Stub
        end
      end

      test_class.new
      assert called
    end

    def test_stimulus_controller_default_true
      assert @test_component_class.stimulus_controller?
    end

    def test_no_stimulus_controller
      test_class = Class.new do
        include Vident::Component
        no_stimulus_controller
      end

      refute test_class.stimulus_controller?
    end

    def test_resolve_root_element_attributes_before_render_with_no_attributes
      options = @component.send(:resolve_root_element_attributes_before_render)
      expected = {
        data: @component.send(:stimulus_data_attributes),
        class: @component.component_name,
        id: @component.id
      }
      assert_equal expected, options
    end

    def test_resolve_root_element_attributes_before_render_with_root_element_html_options
      root_html_options = { 
        class: "test-class",
        data: { test: "value" }
      }
      options = @component.send(:resolve_root_element_attributes_before_render, root_html_options)
      expected = {
        data: @component.send(:stimulus_data_attributes).merge(test: "value"),
        class: "test-component test-class",
        id: @component.id
      }
      assert_equal expected, options
    end

    def test_resolve_root_element_attributes_before_render_with_html_options_prop
      component = @test_component_class.new(html_options: { 
        class: "prop-class",
        data: { prop: "value" }
      })
      options = component.send(:resolve_root_element_attributes_before_render)
      
      expected = {
        data: component.send(:stimulus_data_attributes).merge(prop: "value"),
        class: "test-component prop-class",
        id: component.id
      }
      assert_equal expected, options
    end

    def test_resolve_root_element_attributes_before_render_precedence_order
      component = @test_component_class.new(html_options: { 
        class: "highest-precedence",
        data: { prop: "highest" }
      })
      
      root_html_options = { 
        class: "mid-precedence",
        data: { root: "mid", prop: "mid" }
      }
      
      options = component.send(:resolve_root_element_attributes_before_render, root_html_options)
      
      expected = {
        data: component.send(:stimulus_data_attributes).merge(root: "mid", prop: "highest"),
        class: "test-component highest-precedence",
        id: component.id
      }
      assert_equal expected, options
    end

    def test_resolve_root_element_attributes_before_render_with_id
      component = @test_component_class.new(id: "test-id")
      options = component.send(:resolve_root_element_attributes_before_render)
      
      expected = {
        data: component.send(:stimulus_data_attributes),
        class: component.component_name,
        id: "test-id"
      }
      assert_equal expected, options
    end
  end
end
