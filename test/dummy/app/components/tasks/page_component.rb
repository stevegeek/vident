# frozen_string_literal: true

module Tasks
  class PageComponent < ApplicationComponent
    prop :tasks, _Array(Hash), default: -> { [] }
    prop :active_filter, _Union(:all, :todo, :done, :wont_do), default: :all

    stimulus do
      # Procs run in the component instance context at render time, so these
      # pick up @active_filter / @tasks from the props.
      values active_filter: -> { @active_filter.to_s },
        count: -> { @tasks.size }

      # Cross-controller listener: `stimulus_scoped_event_on_window(:filter_changed)`
      # expands to the symbol `tasks--filter-bar-component:filterChanged@window`,
      # which Vident turns into a data-action tying the filter bar's dispatched
      # event to #handleFilterChanged on this controller.
      actions -> { [FilterBarComponent.stimulus_scoped_event_on_window(:filter_changed), :handle_filter_changed] }
    end

    def view_template
      root_element(class: "space-y-6") do |page|
        render FilterBarComponent.new(active_filter: @active_filter, total: @tasks.size)

        div(class: "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4") do
          @tasks.each do |task|
            # `stimulus_outlet_host: page` is the self-registration hook: each
            # card adds itself to the page's outlet collection in
            # after_initialize, so the page doesn't have to enumerate cards
            # in its own `stimulus do ... outlets`.
            render TaskCardComponent.new(
              task_id: task[:id],
              title: task[:title],
              due: task[:due].to_s,
              list: task[:list],
              status: task[:status],
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
