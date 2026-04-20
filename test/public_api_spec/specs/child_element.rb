# frozen_string_literal: true

module Vident
  module PublicApiSpec
    # Covers: `child_element(tag, stimulus_*: ..., **html_opts, &block)`.
    # Accepts 7 singular + 7 plural stimulus kwargs (one per primitive),
    # arbitrary HTML options, and a block. Plural kwargs require an
    # Enumerable; passing a scalar raises ArgumentError.
    module ChildElement
      # ---- basic render --------------------------------------------------

      def test_child_element_renders_named_tag_with_block_content
        klass = define_component(name: "FooComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element { child_element(:span) { plain "hello" } }
            end
          else
            define_method(:call) do
              root_element { child_element(:span) { "hello" } }
            end
          end
        end
        assert_match(/<span[^>]*>hello<\/span>/, render(klass.new))
      end

      def test_child_element_passes_through_html_options
        klass = define_component(name: "FooComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element { child_element(:button, type: "button", class: "btn") { plain "Go" } }
            end
          else
            define_method(:call) do
              root_element { child_element(:button, type: "button", class: "btn") { "Go" } }
            end
          end
        end
        html = render(klass.new)
        assert_match(/<button[^>]*type="button"/, html)
        assert_match(/<button[^>]*class="btn"/, html)
      end

      # ---- stimulus_* singular kwargs -----------------------------------

      def test_child_element_stimulus_target_singular
        klass = define_component(name: "FormComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element { child_element(:input, stimulus_target: :search) }
            end
          else
            define_method(:call) do
              root_element { child_element(:input, stimulus_target: :search) }
            end
          end
        end
        assert_match(/<input[^>]*data-form-component-target="search"/, render(klass.new))
      end

      def test_child_element_stimulus_action_singular
        klass = define_component(name: "ButtonComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element { child_element(:button, stimulus_action: [:click, :submit]) { plain "Go" } }
            end
          else
            define_method(:call) do
              root_element { child_element(:button, stimulus_action: [:click, :submit]) { "Go" } }
            end
          end
        end
        assert_match(/data-action="click->button-component#submit"/, render(klass.new))
      end

      # ---- stimulus_* plural kwargs -------------------------------------

      def test_child_element_stimulus_targets_plural
        klass = define_component(name: "FormComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element { child_element(:div, stimulus_targets: [:a, :b]) }
            end
          else
            define_method(:call) do
              root_element { child_element(:div, stimulus_targets: [:a, :b]) }
            end
          end
        end
        assert_match(/data-form-component-target="a b"/, render(klass.new))
      end

      def test_child_element_plural_kwarg_requires_enumerable
        # SPEC-NOTE: a scalar passed to a plural kwarg raises with a hint
        # pointing at the singular form (child_element_helper.rb:52).
        klass = define_component(name: "FormComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element { child_element(:div, stimulus_targets: :oops) }
            end
          else
            define_method(:call) do
              root_element { child_element(:div, stimulus_targets: :oops) }
            end
          end
        end
        error = assert_raises(ArgumentError) { render(klass.new) }
        assert_match(/must be an enumerable/, error.message)
        assert_match(/Did you mean 'stimulus_target:'/, error.message)
      end

      # ---- multiple stimulus kwargs compose -----------------------------

      def test_child_element_combines_stimulus_attrs
        klass = define_component(name: "ButtonComponent") do
          if ancestors.include?(::Phlex::HTML)
            define_method(:view_template) do
              root_element do
                child_element(:button,
                  stimulus_action: [:click, :promote],
                  stimulus_target: :submit_button,
                  stimulus_value: [:label, "Go"],
                  type: "button") { plain "Go" }
              end
            end
          else
            define_method(:call) do
              root_element do
                child_element(:button,
                  stimulus_action: [:click, :promote],
                  stimulus_target: :submit_button,
                  stimulus_value: [:label, "Go"],
                  type: "button") { "Go" }
              end
            end
          end
        end
        html = render(klass.new)
        assert_match(/data-action="click->button-component#promote"/, html)
        assert_match(/data-button-component-target="submitButton"/, html)
        assert_match(/data-button-component-label-value="Go"/, html)
        assert_match(/type="button"/, html)
      end
    end
  end
end
