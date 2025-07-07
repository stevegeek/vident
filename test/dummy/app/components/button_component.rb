# frozen_string_literal: true

class ButtonComponent < Vident::ViewComponent::Base
  # Define typed properties
  prop :text, String, default: "Click me"
  prop :url, _Nilable(String)
  prop :style, Symbol, default: :primary
  prop :clicked_count, Integer, default: 0
  
  # Configure Stimulus integration
  stimulus do
    actions [:click, :handle_click]
    # Static values
    values loading_duration: 1000
    # Map the clicked_count prop as a Stimulus value
    values_from_props :clicked_count
    classes loading: "opacity-50 cursor-wait"
  end

  # Using the call method instead of ERB template
  def call
    root_element do
      @text
    end
  end

  private

  def root_element_attributes
    {
      element_tag: @url ? :a : :button,
      html_options: { href: @url }.compact
    }
  end

  def element_classes
    base_classes = "btn"
    case @style
    when :primary
      "#{base_classes} btn-primary"
    when :secondary
      "#{base_classes} btn-secondary"
    end
  end
end