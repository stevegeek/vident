# frozen_string_literal: true

module Tasks
  class TaskCardComponent < ApplicationComponent
    prop :task_id, Integer
    prop :title, String
    prop :due, String, default: ""
    prop :list, _Union(:today, :this_week, :backlog), default: :today
    prop :status, _Union(:todo, :done, :wont_do), default: :todo

    stimulus do
      values_from_props :task_id, :title, :status

      # Three named class lists — Stimulus exposes each as `this.<name>Classes`
      # in the JS controller, so the controller can swap borders + background
      # when status changes without hard-coding Tailwind utilities in JS.
      classes todo: "border-yellow-400 bg-yellow-50",
        done: "border-green-500 bg-green-50",
        wont_do: "border-gray-400 bg-gray-50"

      action(:select).on(:click)
    end

    def view_template
      root_element(
        class: "block cursor-pointer rounded-lg border-2 p-4 shadow-sm transition hover:shadow-md #{class_list_for_stimulus_classes(@status)}",
        role: "button",
        tabindex: 0
      ) do |card|
        div(class: "flex items-start justify-between gap-2") do
          card.child_element(
            :h3,
            stimulus_target: :title_text,
            class: "font-semibold text-gray-900 #{"line-through text-gray-500" if @status == :wont_do}"
          ) { @title }
          span(class: "rounded-full bg-white px-2 py-0.5 text-xs font-medium text-gray-700") { @list.to_s.tr("_", " ") }
        end

        if @due.present?
          p(class: "mt-1 text-xs text-gray-500") { "Due: #{@due}" }
        end

        card.child_element(
          :p,
          stimulus_target: :status_text,
          class: "mt-3 text-xs uppercase tracking-wide text-gray-500"
        ) { @status.to_s.tr("_", " ") }

        div(class: "mt-3 flex gap-2") do
          # Both buttons share an `apply` handler; the controller reads
          # `event.params.kind` to tell them apart, matching each button's
          # `stimulus_params:` declaration.
          done_disabled = (@status == :done)
          dismiss_disabled = (@status == :wont_do)
          done_attrs = {
            stimulus_action: [:click, :apply],
            stimulus_target: :done_button,
            stimulus_params: {kind: "done"},
            type: "button",
            class: "flex-1 rounded bg-green-600 px-2 py-1 text-xs font-medium text-white hover:bg-green-700 disabled:opacity-50"
          }
          done_attrs[:disabled] = true if done_disabled
          card.child_element(:button, **done_attrs) { "Mark done" }

          dismiss_attrs = {
            stimulus_action: [:click, :apply],
            stimulus_target: :dismiss_button,
            stimulus_params: {kind: "dismissed"},
            type: "button",
            class: "flex-1 rounded border border-gray-400 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50"
          }
          dismiss_attrs[:disabled] = true if dismiss_disabled
          card.child_element(:button, **dismiss_attrs) { "Won't do" }
        end
      end
    end
  end
end
