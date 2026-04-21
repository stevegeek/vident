# frozen_string_literal: true

module GreetersV2
  class GreeterButtonComponent < ApplicationComponent
    # Lock the identifier path to V1's so existing
    # greeters/greeter_button_component_controller.js resolves to this
    # V2 component without a JS duplicate.
    class << self
      def stimulus_identifier_path = "greeters/greeter_button_component"
    end

    prop :after_clicked_message, String, default: -> { "Greeted!" }, reader: :private
    prop :before_clicked_message, String, default: -> { "Greet" }, reader: :private

    # Demonstrates the `root_element_attributes`-driven shape. V2's
    # Resolver absorbs these `stimulus_*` keys into the Draft so they
    # emit just like DSL entries.
    private def root_element_attributes
      {
        element_tag: :button,
        stimulus_actions: [:change_message],
        stimulus_values: {after_clicked_message: after_clicked_message, before_clicked_message: before_clicked_message},
        html_options: {class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"}
      }
    end

    def call
      root_element do
        @before_clicked_message
      end
    end
  end
end
