# frozen_string_literal: true

module PhlexGreeters
  class GreeterVidentComponent < ApplicationComponent
    prop :cta, String

    def view_template
      render root do |greeter|
        input type: "text",
          data: {**greeter.stimulus_targets(:name, :another_name)},
          class: "shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"

        # Or the tag helper
        # greeter.tag(:input, stimulus_targets: [:name, :another_name], type: "text", class: "...")

        button(
          data: {**greeter.stimulus_actions([:greet, [:click, :another_action]])},
          class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        ) do
          plain @cta
        end

        # Or the tag helper
        # greeter.tag(:button, stimulus_actions: [:greet, [:click, :another_action]], class: "...") do
        # or
        # greeter.tag(:button, stimulus_actions: [{event: :click, action: :greet}, {event: :click, action: :another_action}], class: "...") do

        span(
          data: greeter.stimulus_target(:output),
          class: "ml-4 text-xl text-gray-700"
        )

        # Or the tag helper
        # greeter.tag(:span, stimulus_targets: :output, class: "ml-4 text-xl text-gray-700")
      end
    end
  end
end
