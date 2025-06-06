# frozen_string_literal: true

module TypedPhlex
  class GreeterButtonComponent < ApplicationComponent
    attribute :after_clicked_message, String, default: "Greeted!"
    attribute :before_clicked_message, String, default: "Greet"

    private

    def root_element_attributes
      {
        element_tag: :button,
        actions: [:change_message],
        values: [{after_clicked_message: @after_clicked_message, before_clicked_message: @before_clicked_message}],
        html_options: {class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"}
      }
    end

    def view_template
      render root do
        @before_clicked_message
      end
    end
  end
end
