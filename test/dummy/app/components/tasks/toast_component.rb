# frozen_string_literal: true

module Tasks
  class ToastComponent < ApplicationComponent
    prop :auto_dismiss_ms, Integer, default: 4000

    stimulus do
      values_from_props :auto_dismiss_ms

      # `Vident::StimulusNull` → the data attribute is emitted as the literal
      # string "null", which Stimulus parses via JSON.parse for Object-typed
      # values. The JS reads `this.messageValue === null` until the first event.
      values message: -> { Vident::StimulusNull }

      # Multiple window listeners + one local click — the DSL takes a variadic
      # list, each entry resolving via the shared action parser.
      actions -> { [TaskCardComponent.stimulus_scoped_event_on_window(:done), :handle_done] },
        -> { [TaskCardComponent.stimulus_scoped_event_on_window(:dismissed), :handle_dismissed] },
        :dismiss
    end

    def view_template
      root_element(class: "pointer-events-none fixed bottom-6 left-1/2 -translate-x-1/2") do |toast|
        toast.child_element(
          :div,
          stimulus_target: :container,
          class: "pointer-events-auto flex items-center gap-3 rounded-lg bg-gray-900 px-4 py-2 text-sm text-white opacity-0 translate-y-4 transition-all duration-200"
        ) do
          toast.child_element(:span, stimulus_target: :message, class: "font-medium") { "" }
          toast.child_element(
            :button,
            stimulus_action: :dismiss,
            type: "button",
            class: "rounded p-0.5 text-gray-400 hover:text-white"
          ) { "✕" }
        end
      end
    end
  end
end
