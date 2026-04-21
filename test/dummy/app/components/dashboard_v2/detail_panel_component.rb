# frozen_string_literal: true

module DashboardV2
  class DetailPanelComponent < ApplicationComponent
    # Identifier locked to V1's so the existing detail_panel_component JS
    # controller resolves without duplication.
    class << self
      def stimulus_identifier_path = "dashboard/detail_panel_component"
    end

    stimulus do
      # Returning bare `nil` from a value proc would omit the data attribute
      # entirely. `Vident::StimulusNull` serialises to the literal string
      # `"null"`, which Stimulus's Object parser runs through JSON.parse,
      # giving the JS side an honest `null` until a card is actually selected.
      values release: -> { Vident::StimulusNull }

      # A static class value — the JS controller toggles the `translate-x-full`
      # suffix when showing/hiding. `class_list_for_stimulus_classes(:state)`
      # below resolves it for the initial SSR render.
      classes state: "fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"

      # Three action entries on the same controller:
      # 1. Scoped window event from a card → opens the panel. The proc
      #    defers resolving `ReleaseCardComponent` until instance init,
      #    which avoids class-load ordering issues.
      actions -> { [ReleaseCardComponent.stimulus_scoped_event_on_window(:selected), :handle_selected] }
      # 2. Global Escape key closes the panel. The fluent form reads as
      #    "the close method fires on a keydown event, filtered to the
      #    `esc` key, listening at window scope". Emits
      #    `keydown.esc@window->dashboard--detail-panel-component#close`.
      action(:close).on(:keydown).keyboard("esc").window
      # 3. Plain close — the close button's explicit click target (no
      #    event prefix, no chain).
      action :close
    end

    def view_template
      root_element(class: class_list_for_stimulus_classes(:state)) do |panel|
        div(class: "flex items-start justify-between") do
          h2(class: "text-lg font-semibold") { "Release detail" }
          panel.child_element(
            :button,
            stimulus_action: :close,
            type: "button",
            class: "rounded p-1 text-gray-500 hover:bg-gray-100 hover:text-gray-900"
          ) { "✕" }
        end

        panel.child_element(:div, stimulus_target: :body, class: "mt-4 space-y-2 text-sm text-gray-700") do
          p(class: "italic text-gray-400") { "Click a release to see details." }
        end
      end
    end
  end
end
