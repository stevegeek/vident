# frozen_string_literal: true

module Dashboard
  class FilterBarComponent < ApplicationComponent
    # Identifier locked to V1's so the existing filter_bar_component JS
    # controller resolves without duplication.
    class << self
      def stimulus_identifier_path = "dashboard/filter_bar_component"
    end

    STATUSES = %i[all pending deployed failed].freeze

    prop :active_filter, _Union(:all, :pending, :deployed, :failed), default: :all
    prop :total, Integer, default: 0

    stimulus do
      # `values_from_props` mirrors the :active_filter prop into a Stimulus
      # value without a second declaration. JS reads `this.activeFilterValue`.
      values_from_props :active_filter

      # filter_select / search_input are wired onto their specific child
      # elements below. The root only needs the reverse-channel listener:
      # the page dispatches filterApplied with the visible count so we can
      # repaint the badge.
      actions -> { [PageComponent.stimulus_scoped_event_on_window(:filter_applied), :handle_filter_applied] }
    end

    def view_template
      root_element(class: "flex flex-wrap items-center gap-3 rounded-lg bg-gray-50 p-3") do |bar|
        label(class: "text-sm font-medium text-gray-700") { "Status" }

        # `child_element` builds a tag with stimulus_* kwargs resolved into
        # data attributes. `[:change, :filter_select]` means "on change event,
        # fire the filter_select action on this controller".
        bar.child_element(
          :select,
          stimulus_action: [:change, :filter_select],
          class: "rounded border-gray-300 bg-white px-2 py-1 text-sm"
        ) do
          STATUSES.each do |status|
            option(value: status, selected: (status == @active_filter)) { status.to_s.capitalize }
          end
        end

        bar.child_element(
          :input,
          stimulus_target: :search,
          stimulus_action: [:input, :search_input],
          type: "search",
          placeholder: "Filter by name…",
          class: "flex-1 min-w-[12rem] rounded border-gray-300 px-2 py-1 text-sm"
        )

        span(class: "ml-auto text-sm text-gray-500") do
          plain "Visible: "
          bar.child_element(
            :span,
            stimulus_target: :count,
            class: "font-semibold text-gray-900"
          ) { @total.to_s }
        end
      end
    end
  end
end
