# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  # child_element is the per-tag DSL used inside root_element blocks.
  # Covered through the Phlex adapter since it's the richer path
  # (VALID_TAGS guard); the VC adapter runs the same kwarg parsing via
  # the component-level surface so its coverage comes from the public
  # spec suite.
  class ChildElementTest < Minitest::Test
    def make_phlex(name: "FormComponent", &block)
      klass = Class.new(::Vident::Phlex::HTML)
      klass.define_singleton_method(:name) { name }
      klass.class_eval(&block) if block
      unless klass.instance_methods(false).include?(:view_template)
        klass.define_method(:view_template) { root_element }
      end
      klass
    end

    def render(klass, **props) = klass.new(**props).call.to_s

    # ---- singular kwargs ------------------------------------------------

    def test_singular_stimulus_target_emits_data_target_attribute
      klass = make_phlex do
        define_method(:view_template) { root_element { child_element(:input, stimulus_target: :search) } }
      end
      assert_match(/data-form-component-target="search"/, render(klass))
    end

    def test_singular_stimulus_action_with_event_method_form
      klass = make_phlex(name: "ButtonComponent") do
        define_method(:view_template) do
          root_element { child_element(:button, stimulus_action: [:click, :submit]) { plain "Go" } }
        end
      end
      assert_match(/data-action="click->button-component#submit"/, render(klass))
    end

    # ---- plural kwargs --------------------------------------------------

    def test_plural_stimulus_targets_accepts_array
      klass = make_phlex do
        define_method(:view_template) { root_element { child_element(:div, stimulus_targets: [:a, :b]) } }
      end
      assert_match(/data-form-component-target="a b"/, render(klass))
    end

    def test_plural_kwarg_with_scalar_input_raises
      klass = make_phlex do
        define_method(:view_template) { root_element { child_element(:div, stimulus_targets: :oops) } }
      end
      error = assert_raises(ArgumentError) { render(klass) }
      assert_match(/must be an enumerable/, error.message)
      assert_match(/stimulus_target/, error.message)
    end

    # Guards against a V1 bug where `stimulus_target: :x, stimulus_targets: []`
    # would silently drop the singular (empty array is truthy). V2 refuses
    # ambiguous input outright so the latent bug can't regress.
    def test_both_plural_and_singular_stimulus_kwargs_raise
      klass = make_phlex do
        define_method(:view_template) do
          root_element { child_element(:input, stimulus_target: :input, stimulus_targets: []) }
        end
      end
      error = assert_raises(ArgumentError) { render(klass) }
      assert_match(/mutually exclusive/, error.message)
      assert_match(/stimulus_targets/, error.message)
      assert_match(/stimulus_target/, error.message)
    end

    def test_both_plural_and_singular_stimulus_actions_raise
      klass = make_phlex do
        define_method(:view_template) do
          root_element { child_element(:button, stimulus_action: :click, stimulus_actions: [[:click, :handle]]) }
        end
      end
      error = assert_raises(ArgumentError) { render(klass) }
      assert_match(/mutually exclusive/, error.message)
    end

    def test_empty_plural_alone_emits_no_data_attribute
      klass = make_phlex do
        define_method(:view_template) { root_element { child_element(:div, stimulus_targets: []) } }
      end
      refute_match(/data-.*-target/, render(klass))
    end

    # ---- html options pass-through --------------------------------------

    def test_html_options_pass_through
      klass = make_phlex do
        define_method(:view_template) do
          root_element { child_element(:button, type: "button", class: "btn") { plain "Go" } }
        end
      end
      html = render(klass)
      assert_match(/type="button"/, html)
      assert_match(/class="btn"/, html)
    end

    # ---- invalid tag guard ---------------------------------------------

    def test_invalid_tag_raises_argument_error
      klass = make_phlex do
        define_method(:view_template) { root_element { child_element(:bogus_tag) } }
      end
      assert_raises(ArgumentError) { render(klass) }
    end

    # ---- combined stimulus kwargs ---------------------------------------

    def test_combined_stimulus_kwargs_render_together
      klass = make_phlex(name: "ButtonComponent") do
        define_method(:view_template) do
          root_element do
            child_element(:button,
              stimulus_action: [:click, :handle],
              stimulus_target: :submit_button,
              stimulus_value: [:label, "Go"],
              type: "button") { plain "Go" }
          end
        end
      end
      html = render(klass)
      assert_match(/data-action="click->button-component#handle"/, html)
      assert_match(/data-button-component-target="submitButton"/, html)
      assert_match(/data-button-component-label-value="Go"/, html)
      assert_match(/type="button"/, html)
    end
  end
end
