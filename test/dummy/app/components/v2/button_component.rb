# frozen_string_literal: true

require "vident2"

module V2
  class ButtonComponent < ::Vident2::ViewComponent::Base
    # Lock the identifier to match V1's so the same
    # app_components/button_component_controller.js resolves to this
    # V2 component without duplication. Emitted data-controller stays
    # `button-component`.
    class << self
      def stimulus_identifier_path = "button_component"
    end

    # Typed props — Literal-backed.
    prop :text, String, default: "Click me"
    prop :url, _Nilable(String)
    prop :style, Symbol, default: :primary
    prop :clicked_count, Integer, default: 0

    # V1-equivalent Stimulus DSL. Each primitive does the same thing as
    # V1 with a faithful surface; procs are evaluated in the instance
    # binding at render time (so they can read props/ivars).
    stimulus do
      actions [:click, :handle_click]
      # Static values
      values loading_duration: 1000
      # Map the clicked_count prop straight through as a Stimulus value.
      values_from_props :clicked_count
      # Dynamic values — the Resolver evaluates these against `self` at
      # render time, so @items / Rails helpers are in scope.
      values item_count: -> { @items&.count || 0 }
      values api_url: -> { Rails.application.routes.url_helpers.root_path }
      # Static and dynamic classes
      classes loading: "opacity-50 cursor-wait"
      classes size: -> { ((@items&.count || 0) > 10) ? "large" : "small" }
    end

    def call
      root_element do |component|
        component.child_element(:span, stimulus_target: :status) do
          @text
        end
      end
    end

    private

    def root_element_attributes
      {
        element_tag: @url ? :a : :button,
        html_options: {href: @url}.compact
      }
    end

    def root_element_classes
      base_classes = "btn"
      case @style
      when :primary
        "#{base_classes} btn-primary"
      when :secondary
        "#{base_classes} btn-secondary"
      end
    end
  end
end
