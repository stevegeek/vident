# frozen_string_literal: true

module Dashboard
  class ReleaseCardComponent < ApplicationComponent
    # Lock the stimulus identifier to match the V1 component's, so the
    # existing `app_components/dashboard/release_card_component_controller.js`
    # still resolves against this V2 component without duplication.
    # Emitted `data-controller="dashboard--release-card-component"`.
    class << self
      def stimulus_identifier_path = "dashboard/release_card_component"
    end

    prop :release_id, Integer
    prop :name, String
    prop :version, String
    prop :environment, _Union(:production, :staging, :preview), default: :staging
    prop :status, _Union(:pending, :deployed, :failed), default: :pending

    # `stimulus_outlet_host:` is inherited from Vident::Component. Passing
    # the parent page at render time causes this card to call
    # `host.add_stimulus_outlets(self)` in after_initialize, which wires a
    # `data-dashboard--page-component-dashboard--release-card-component-outlet`
    # attribute onto the host's root element.

    stimulus do
      # Mirrors the :release_id / :name / :status props straight through as
      # Stimulus values. No second declaration needed — the Resolver reads
      # the `@ivar` current value at render time.
      values_from_props :release_id, :name, :status

      # Proc evaluated in the component instance, so it sees @status. The DSL
      # emits a `data-<controller>-status-class="..."` attribute on the root
      # which Stimulus exposes as `this.statusClasses` in the JS controller.
      # `class_list_for_stimulus_classes(:status)` below inlines the same
      # resolved value into the `class=` attribute for the first render.
      classes status: -> {
        case @status
        when :deployed then "border-green-500 bg-green-50"
        when :failed then "border-red-500 bg-red-50"
        else "border-yellow-400 bg-yellow-50"
        end
      }

      # Fluent builder: reads left-to-right as "the `select` method fires
      # on the `click` event". Emits `click->implied#select`. Equivalent
      # V1-style shorthand `actions [:click, :select]` still works.
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
          # Demo of Stimulus params: one `apply` handler for both buttons, with
          # `stimulus_params: { kind: ... }` on the element so the handler reads
          # `event.params.kind` to tell which button fired. In a real app you'd
          # probably just keep separate `promote` / `cancel` handlers — this
          # intentional "one dispatch switch" shape is a bit RPC-ish and is
          # here to show what the params feature looks like.
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
