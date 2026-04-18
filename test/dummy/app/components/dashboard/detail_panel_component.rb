# frozen_string_literal: true

module Dashboard
  class DetailPanelComponent < ApplicationComponent
    stimulus do
      # Returning bare `nil` from a value proc would omit the data attribute
      # entirely (Stimulus would fall back to the Object type default `{}`).
      # `Vident::StimulusNull` serialises to the literal string `"null"`, which
      # Stimulus's Object parser runs through JSON.parse, giving the JS side an
      # honest `null` until a card is actually selected.
      values release: -> { Vident::StimulusNull }

      # A static class value — the JS controller toggles the `translate-x-full`
      # suffix when showing/hiding. `class_list_for_stimulus_classes(:state)`
      # below resolves it for the initial SSR render.
      classes state: "fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"

      # Listen on window for the card's scoped `selected` event, and handle a
      # plain click on this component's own close button.
      actions -> { [ReleaseCardComponent.stimulus_scoped_event_on_window(:selected), :handle_selected] },
        :close
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
