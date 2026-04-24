# frozen_string_literal: true

module Vident
  module PublicApiSpec
    module RootElementHelpers
      # ---- root_element_class_list ------------------------------------------

      def test_class_list_matches_class_emitted_by_root_element
        klass = define_component(name: "CardComponent")
        html = render(klass.new)
        comp = klass.new
        assert_match(/class="#{Regexp.escape(comp.root_element_class_list)}"/, html)
      end

      def test_class_list_with_classes_prop_matches_root_element
        klass = define_component(name: "CardComponent")
        comp = klass.new(classes: "extra")
        html = render(comp.with)
        assert_match(/class="#{Regexp.escape(comp.root_element_class_list)}"/, html)
      end

      def test_class_list_with_html_options_class_matches_root_element
        klass = define_component(name: "CardComponent")
        comp = klass.new(html_options: {class: "themed"})
        html = render(comp.with)
        assert_match(/class="#{Regexp.escape(comp.root_element_class_list)}"/, html)
      end

      def test_class_list_extra_classes_appended_after_cascade
        klass = define_component(name: "ButtonComponent")
        comp = klass.new(classes: "primary")
        result = comp.root_element_class_list("appended")
        assert_match(/button-component/, result)
        assert_match(/primary/, result)
        assert_match(/appended/, result)
        assert result.index("primary") < result.index("appended")
      end

      def test_class_list_no_stimulus_controller_still_emits_component_name
        klass = define_component(name: "IconComponent") do
          no_stimulus_controller
        end
        result = klass.new.root_element_class_list
        assert_match(/icon-component/, result)
      end

      def test_class_list_returns_string
        klass = define_component(name: "CardComponent")
        assert_kind_of String, klass.new.root_element_class_list
      end

      def test_class_list_tailwind_merge_resolves_conflict
        skip "Tailwind merger not loaded" unless defined?(::TailwindMerge::Merger)
        klass = define_component(name: "ButtonComponent")
        # p-2 from html_options, p-4 from extra_classes — merger keeps last
        comp = klass.new(html_options: {class: "p-2"})
        result = comp.root_element_class_list("p-4")
        assert_match(/p-4/, result)
        refute_match(/p-2/, result)
      end

      # ---- root_element_data_attributes ------------------------------------

      def test_data_attributes_contains_controller_key
        klass = define_component(name: "ButtonComponent")
        attrs = klass.new.root_element_data_attributes
        assert_equal "button-component", attrs[:controller]
      end

      def test_data_attributes_no_stimulus_controller_has_no_controller_key
        klass = define_component(name: "SvgComponent") do
          no_stimulus_controller
        end
        attrs = klass.new.root_element_data_attributes
        refute attrs.key?(:controller), "no_stimulus_controller should suppress :controller"
      end

      def test_data_attributes_matches_root_element_data_output
        klass = define_component(name: "CardComponent") do
          stimulus do
            actions :click
            values label: "hello"
          end
        end
        comp = klass.new
        html = render(comp.with)
        attrs = comp.root_element_data_attributes
        assert_match(/data-controller="card-component"/, html)
        assert_equal "card-component", attrs[:controller]
        assert_match(/data-action="card-component#click"/, html)
        assert_equal "card-component#click", attrs[:action]
        assert_match(/data-card-component-label-value="hello"/, html)
        assert_equal "hello", attrs[:"card-component-label-value"]
      end

      def test_data_attributes_all_dsl_kinds_present
        klass = define_component(name: "FullComponent") do
          stimulus do
            actions :click
            targets :panel
            values count: 3
            params kind: "go"
            classes loading: "spin"
          end
        end
        attrs = klass.new.root_element_data_attributes
        assert_equal "full-component", attrs[:controller]
        assert_equal "full-component#click", attrs[:action]
        assert_equal "panel", attrs[:"full-component-target"]
        assert_equal "3", attrs[:"full-component-count-value"]
        assert_equal "go", attrs[:"full-component-kind-param"]
        assert_equal "spin", attrs[:"full-component-loading-class"]
      end

      def test_data_attributes_returns_symbol_keyed_hash
        klass = define_component(name: "ButtonComponent")
        attrs = klass.new.root_element_data_attributes
        assert_kind_of Hash, attrs
        attrs.each_key { |k| assert_kind_of Symbol, k }
      end

      def test_data_attributes_idempotent_across_calls
        klass = define_component(name: "ButtonComponent") do
          stimulus { actions :click }
        end
        comp = klass.new
        assert_equal comp.root_element_data_attributes, comp.root_element_data_attributes
      end

      # ---- Rendering parity: helper path vs root_element path ----------------

      def test_helper_path_class_matches_root_element_path
        # A component that renders via root_element (control)
        klass_control = define_component(name: "SvgWidget") do
          stimulus { values mode: "dark" }
        end

        # A component that uses the helpers to populate a plain tag (subject)
        klass_subject = define_component(name: "SvgWidget") do
          stimulus { values mode: "dark" }
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              div(class: root_element_class_list, data: root_element_data_attributes)
            end
          else
            define_method(:call) do
              view_context.content_tag(
                :div,
                nil,
                class: root_element_class_list,
                data: root_element_data_attributes
              )
            end
          end
        end

        control_html = render(klass_control.new)
        subject_html = render(klass_subject.new)

        # Both should have the same class= value
        control_class = control_html[/class="([^"]*)"/, 1]
        subject_class = subject_html[/class="([^"]*)"/, 1]
        assert_equal control_class, subject_class

        # Both should have data-controller
        assert_match(/data-controller="svg-widget"/, subject_html)

        # Both should have the value attribute
        assert_match(/data-svg-widget-mode-value="dark"/, subject_html)
      end
    end
  end
end
