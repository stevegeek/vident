# frozen_string_literal: true

class TypedPhlex::GreeterComponent < ::Phlex::HTML
  def initialize(cta:)
    @cta = cta
  end

  def template
    div(data_controller: "greeter") do
      input data_greeter_target: "name",
            type: "text",
            class: "shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
      button(
        data_action: "click->greeter#greet",
        class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      ) do
        plain @cta
      end
      span data_greeter_target: "output",
           class: "ml-4 text-xl text-gray-700"
    end
  end
end
