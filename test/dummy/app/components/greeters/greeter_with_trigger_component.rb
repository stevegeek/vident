# frozen_string_literal: true

module Greeters
  class GreeterWithTriggerComponent < ApplicationComponent
    renders_one :trigger, GreeterButtonComponent

    def root_element_attributes
      {
        stimulus_classes: {
          pre_click: "text-md text-gray-500",
          post_click: "text-xl text-blue-700"
        }
      }
    end

    def default_trigger
      GreeterButtonComponent.new(
        before_clicked_message: "I'm the trigger! Click me to greet.",
        after_clicked_message: "Greeted! Click me again to reset.",
        stimulus_actions: [
          stimulus_action(:click, :greet)
        ],
        html_options: {
          role: "button"
        }
      )
    end
  end
end
