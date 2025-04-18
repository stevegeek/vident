# frozen_string_literal: true

module TypedPhlex
  class GreeterVidentComponent < ApplicationComponent
    attribute :cta, allow_nil: false

    def view_template
      render root do |greeter|
        input type: "text",
          data: greeter.target_data_attribute(:name),
          class: "shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
        button(
          data: greeter.action_data_attribute([:click, :greet]),
          class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        ) do
          plain @cta
        end
        greeter.target_tag(:span, :output, class: "ml-4 text-xl text-gray-700") # TODO: greeter.span_target(:output) - or maybe span_target which implicit on the root component?
      end
    end
  end
end
