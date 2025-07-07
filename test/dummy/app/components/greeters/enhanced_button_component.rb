# frozen_string_literal: true

module Greeters
  # Example component demonstrating the new optional declarative DSL
  class EnhancedButtonComponent < ApplicationComponent
    prop :text, String, default: "Click me"
    prop :loading, _Boolean, default: false
    prop :error_class, String, default: "text-red-500"
    prop :variant, Symbol, default: :primary

    # NEW: Optional declarative stimulus DSL
    stimulus do
      actions :click, :toggle_loading
      targets :button, :spinner
      values_from_props :text, :loading  # Maps from props with same names
      classes loading: "opacity-50 cursor-not-allowed", success: "text-green-500", error: "text-red-500"
    end

    # EXISTING: Still works - this will be merged with the above
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