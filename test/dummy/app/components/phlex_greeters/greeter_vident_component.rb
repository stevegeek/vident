# frozen_string_literal: true

module PhlexGreeters
  class GreeterVidentComponent < ApplicationComponent
    # Lock to V1's identifier so the existing
    # phlex_greeters/greeter_vident_component_controller.js resolves.
    class << self
      def stimulus_identifier_path = "phlex_greeters/greeter_vident_component"
    end

    prop :cta, String

    def view_template
      root_element do |greeter|
        # `stimulus_targets(:name, :another_name)` returns a Collection;
        # `.to_h` converts into the `data: { ... }` shape Phlex's tag DSL
        # accepts. Equivalent child_element/helper forms are shown below
        # as teaching references.
        input type: "text",
          data: greeter.stimulus_targets(:name, :another_name).to_h,
          class: "shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"

        # Or the child_element helper
        # greeter.child_element(:input, stimulus_targets: [:name, :another_name], type: "text", class: "...")

        button(
          data: {**greeter.stimulus_actions(:greet, [:click, :another_action])},
          class: "ml-4 whitespace-no-wrap bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        ) do
          plain @cta
        end

        # Or the child_element helper
        # greeter.child_element(:button, stimulus_actions: [:greet, [:click, :another_action]], class: "...") do
        # or
        # greeter.child_element(:button, stimulus_actions: [{event: :click, action: :greet}, {event: :click, action: :another_action}], class: "...") do

        span(
          data: greeter.stimulus_target(:output).to_h,
          class: "ml-4 text-xl text-gray-700"
        )

        # Or the child_element helper
        # greeter.child_element(:span, stimulus_targets: :output, class: "ml-4 text-xl text-gray-700")
      end
    end
  end
end
