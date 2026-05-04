# frozen_string_literal: true

module Tasks
  class DetailPanelComponent < ApplicationComponent
    stimulus do
      # Returning bare `nil` from a value proc would omit the data attribute
      # entirely. `Vident::StimulusNull` serialises to the literal string
      # `"null"`, which Stimulus's Object parser runs through JSON.parse,
      # giving the JS side an honest `null` until a card is actually selected.
      values task: -> { Vident::StimulusNull }

      # A static class value — the JS controller toggles the `translate-x-full`
      # suffix when showing/hiding. `class_list_for_stimulus_classes(:state)`
      # below resolves it for the initial SSR render.
      classes state: "fixed right-0 top-0 h-full w-80 border-l bg-white p-6 shadow-xl transition-transform duration-200 translate-x-full"

      # Secondary controller stacked on the panel root, given a short alias
      # so later action entries can refer to it by `:dismissable` instead of
      # the full path. Emits an extra `tasks--dismissable` token in
      # `data-controller`, so Stimulus instantiates both controllers on the
      # same element.
      controller "tasks/dismissable", as: :dismissable

      # Four actions on the panel root. The first two target the implied
      # detail-panel controller; the last two target the :dismissable alias.

      # 1. Scoped window event from a card → opens the panel. The proc
      #    defers resolving `TaskCardComponent` until instance init,
      #    which avoids class-load ordering issues.
      actions -> { [TaskCardComponent.stimulus_scoped_event_on_window(:selected), :handle_selected] }

      # 2. Global Escape key closes the panel — kwargs shorthand for the
      #    fluent chain `action(:close).on(:keydown).keyboard("esc").window`.
      #    Emits `keydown.esc@window->tasks--detail-panel-component#close`.
      action :close, on: :keydown, keyboard: "esc", window: true

      # 3. Backspace also closes, but via the :dismissable alias. The fluent
      #    `.on_controller(:dismissable)` routes the action through the alias
      #    declared above, so the emitted data-action is
      #    `keydown.backspace@window->tasks--dismissable#close` instead
      #    of the implied controller.
      action(:close).on(:keydown).keyboard("backspace").window.on_controller(:dismissable)

      # 4. Kwargs form AND alias together: `on:` sets the event, `on_controller:`
      #    routes through the :dismissable alias. Emits
      #    `dblclick->tasks--dismissable#close`. Equivalent to the
      #    fluent chain `.on(:dblclick).on_controller(:dismissable)`.
      action :close, on: :dblclick, on_controller: :dismissable

      # 5. Plain close — wired to the explicit close button below (no event
      #    prefix, no chain).
      action :close

      # ---- Outlets ------------------------------------------------------
      # `outlets` keys are *child controller identifiers*. For namespaced
      # ids (containing `--`) use the positional-hash form. `nil` value
      # means "build the auto-selector for me", scoped to this component's
      # element id; the JS side reads `this.tasksToastComponentOutlet`.
      outlets({"tasks--toast-component" => nil})
      # For a verbatim CSS selector (e.g. document-wide, escaping the
      # auto-scoping), wrap with `Vident::Selector(...)` — bare strings
      # are rejected, so you can't accidentally pass a controller id where
      # a selector was meant or vice versa:
      #   outlets({"tasks--toast-component" => Vident::Selector("[data-controller~=tasks--toast-component]")})

      # ---- Escape hatch: parsing a serialised Stimulus descriptor -------
      # If you receive an action descriptor as a wire string (config,
      # database, external) rather than authoring it in Ruby, parse it
      # with `Vident::Stimulus::Action.parse_descriptor` and feed the
      # resulting value object back through `actions`. The descriptor is
      # taken verbatim; the controller segment is NOT re-stimulized:
      #   external = "click->tasks--filter-bar-component#focus"
      #   actions ::Vident::Stimulus::Action.parse_descriptor(external)
    end

    def view_template
      root_element(class: class_list_for_stimulus_classes(:state)) do |panel|
        div(class: "flex items-start justify-between") do
          h2(class: "text-lg font-semibold") { "Task detail" }
          panel.child_element(
            :button,
            stimulus_action: :close,
            type: "button",
            class: "rounded p-1 text-gray-500 hover:bg-gray-100 hover:text-gray-900"
          ) { "✕" }
        end

        panel.child_element(:div, stimulus_target: :body, class: "mt-4 space-y-2 text-sm text-gray-700") do
          p(class: "italic text-gray-400") { "Click a task to see details." }
        end
      end
    end
  end
end
