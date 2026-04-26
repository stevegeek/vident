# frozen_string_literal: true

module Phlex
  class TaskCardComponent < ApplicationComponent
    prop :task_id, Integer
    prop :title, String
    prop :priority, _Union(:low, :medium, :high), default: :medium
    prop :status, _Union(:todo, :done, :wont_do), default: :todo
    prop :tags, _Array(String), default: -> { [] }

    stimulus do
      values_from_props :task_id, :title, :status

      classes status: -> {
        case @status
        when :done then "border-green-500 bg-green-50"
        when :wont_do then "border-gray-400 bg-gray-50"
        else "border-yellow-400 bg-yellow-50"
        end
      }

      action(:select).on(:click)
    end

    def view_template
      root_element(
        class: "block cursor-pointer rounded-lg border-2 p-4 shadow-sm transition hover:shadow-md #{class_list_for_stimulus_classes(:status)}",
        role: "button",
        tabindex: 0
      ) do |card|
        div(class: "flex items-center justify-between") do
          h3(class: "font-semibold text-gray-900 #{"line-through text-gray-500" if @status == :wont_do}") { @title }
          span(class: "rounded-full bg-white px-2 py-0.5 text-xs font-medium text-gray-700") { @priority.to_s }
        end

        if @tags.any?
          div(class: "mt-2 flex flex-wrap gap-1") do
            @tags.each do |tag|
              span(class: "rounded bg-white px-2 py-0.5 text-xs text-gray-600 ring-1 ring-gray-200") { tag }
            end
          end
        end

        p(class: "mt-3 text-xs uppercase tracking-wide text-gray-500") { @status.to_s.tr("_", " ") }

        div(class: "mt-3 flex gap-2") do
          card.child_element(
            :button,
            stimulus_action: [:click, :apply],
            stimulus_target: :done_button,
            stimulus_params: {kind: "done"},
            type: "button",
            class: "flex-1 rounded bg-green-600 px-2 py-1 text-xs font-medium text-white hover:bg-green-700 disabled:opacity-50"
          ) { "Mark done" }

          card.child_element(
            :button,
            stimulus_action: [:click, :apply],
            stimulus_target: :wont_do_button,
            stimulus_params: {kind: "wont_do"},
            type: "button",
            class: "flex-1 rounded border border-gray-400 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50"
          ) { "Won't do" }
        end
      end
    end
  end
end
