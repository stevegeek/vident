# frozen_string_literal: true

module Greeters
  # Shows the declarative Stimulus DSL on V2 alongside a VC template.
  class EnhancedButtonComponent < ApplicationComponent
    # Lock to V1's identifier so the existing JS controller resolves.
    class << self
      def stimulus_identifier_path = "greeters/enhanced_button_component"
    end

    prop :text, String, default: "Click me"
    prop :loading, _Boolean, default: false
    prop :error_class, String, default: "text-red-500"
    prop :variant, Symbol, default: :primary

    stimulus do
      actions :click, :toggle_loading
      targets :button, :spinner
      values_from_props :text, :loading
      classes loading: "opacity-50 cursor-not-allowed",
        success: "text-green-500",
        error: "text-red-500"
    end

    # DSL + root_element_attributes merge: the DSL entries above land on
    # the Draft first, then this hash's `html_options`/class get folded
    # into the final root element at render.
    def root_element_attributes
      {
        element_tag: :button,
        html_options: {
          class: variant_classes,
          disabled: @loading
        }
      }
    end

    private

    def variant_classes
      case @variant
      when :primary
        "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      when :secondary
        "bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded"
      else
        "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      end
    end
  end
end
