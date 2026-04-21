# frozen_string_literal: true

module DashboardV2
  class PageComponent < ApplicationComponent
    # Identifier locked to V1's so the existing page_component JS
    # controller resolves without duplication. Emitted data-controller
    # stays `dashboard--page-component`.
    class << self
      def stimulus_identifier_path = "dashboard/page_component"
    end

    prop :releases, _Array(Hash), default: -> { [] }
    prop :active_filter, _Union(:all, :pending, :deployed, :failed), default: :all

    stimulus do
      # Procs run in the component instance context at render time, so these
      # pick up @active_filter / @releases from the props.
      values active_filter: -> { @active_filter.to_s },
        count: -> { @releases.size }

      # Cross-controller listener: `stimulus_scoped_event_on_window(:filter_changed)`
      # expands to the symbol `dashboard--filter-bar-component:filterChanged@window`,
      # which Vident turns into a data-action tying the filter bar's dispatched
      # event to #handleFilterChanged on this controller.
      actions -> { [FilterBarComponent.stimulus_scoped_event_on_window(:filter_changed), :handle_filter_changed] }
    end

    def view_template
      root_element(class: "space-y-6") do |page|
        render FilterBarComponent.new(active_filter: @active_filter, total: @releases.size)

        div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
          @releases.each do |release|
            # `stimulus_outlet_host: page` is the self-registration hook: each
            # card adds itself to the page's outlet collection in
            # after_initialize, so the page doesn't have to enumerate cards
            # in its own `stimulus do ... outlets`.
            render ReleaseCardComponent.new(
              release_id: release[:id],
              name: release[:name],
              version: release[:version],
              environment: release[:environment],
              status: release[:status],
              stimulus_outlet_host: page
            )
          end
        end

        render DetailPanelComponent.new
        render ToastComponent.new
      end
    end
  end
end
