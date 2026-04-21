# frozen_string_literal: true

module GreetersV2
  class GreeterWithTriggerComponent < ApplicationComponent
    # Lock to V1's identifier so the existing JS controller resolves.
    class << self
      def stimulus_identifier_path = "greeters/greeter_with_trigger_component"
    end

    renders_one :trigger, GreeterButtonComponent

    # `stimulus_classes:` in root_element_attributes is absorbed into
    # the Draft by the Resolver, so the attributes emit as DSL entries.
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
        # Pass a pre-parsed Stimulus::Action — this is how V2's Draft
        # accepts value objects from user code (V1 used the same shape
        # via a Descriptor class, now folded into Stimulus::Action).
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
