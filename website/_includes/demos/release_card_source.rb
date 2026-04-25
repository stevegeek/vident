# frozen_string_literal: true

module Dashboard
  class ReleaseCardComponent < ApplicationComponent
    prop :release_id, Integer
    prop :name, String
    prop :version, String
    prop :environment, _Union(:production, :staging, :preview), default: :staging
    prop :status, _Union(:pending, :deployed, :failed), default: :pending

    stimulus do
      values_from_props :release_id, :name, :status

      # Procs run in the component instance at render time, so they see
      # `@status`. `class_list_for_stimulus_classes(:status)` inlines the
      # same value into `class=` for the first paint.
      classes status: -> {
        case @status
        when :deployed then "border-green-500 bg-green-50"
        when :failed then "border-red-500 bg-red-50"
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
          div do
            h3(class: "font-semibold text-gray-900") { @name }
            p(class: "text-sm text-gray-500") { "v#{@version}" }
          end
          span(class: "rounded-full bg-white px-2 py-0.5 text-xs font-medium text-gray-700") { @environment.to_s }
        end

        p(class: "mt-3 text-xs uppercase tracking-wide text-gray-500") { @status.to_s }

        div(class: "mt-3 flex gap-2") do
          # Both buttons share an `apply` handler; the controller reads
          # `event.params.kind` to tell them apart, matching each button's
          # `stimulus_params:` declaration.
          card.child_element(
            :button,
            stimulus_action: [:click, :apply],
            stimulus_target: :promote_button,
            stimulus_params: {kind: "promote"},
            type: "button",
            class: "flex-1 rounded bg-blue-600 px-2 py-1 text-xs font-medium text-white hover:bg-blue-700 disabled:opacity-50"
          ) { "Promote" }

          card.child_element(
            :button,
            stimulus_action: [:click, :apply],
            stimulus_target: :cancel_button,
            stimulus_params: {kind: "cancel"},
            type: "button",
            class: "flex-1 rounded border border-red-500 px-2 py-1 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50"
          ) { "Cancel" }
        end
      end
    end
  end
end
