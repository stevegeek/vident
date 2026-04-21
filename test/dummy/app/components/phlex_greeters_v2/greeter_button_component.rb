# frozen_string_literal: true

module PhlexGreetersV2
  class GreeterButtonComponent < ApplicationComponent
    # Lock to V1's identifier so the existing
    # phlex_greeters/greeter_button_component_controller.js resolves
    # to this V2 component without duplication.
    class << self
      def stimulus_identifier_path = "phlex_greeters/greeter_button_component"
    end

    prop :after_clicked_message, String, default: "Greeted!"
    prop :before_clicked_message, String, default: "Greet"

    private

    def root_element_attributes
      {
        element_tag: :button,
        stimulus_actions: [:change_message],
        stimulus_values: {after_clicked_message: @after_clicked_message, before_clicked_message: @before_clicked_message},
        html_options: {class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"}
      }
    end

    def view_template
      root_element do
        plain @before_clicked_message
      end
    end
  end
end
