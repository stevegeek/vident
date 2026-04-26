# task_card_component.rb
# frozen_string_literal: true

module ViewComponent
  class TaskCardComponent < ::Vident::ViewComponent::Base
    prop :task_id, Integer
    prop :title, String, reader: :public
    prop :priority, _Union(:low, :medium, :high), default: :medium, reader: :public
    prop :status, _Union(:todo, :done, :wont_do), default: :todo, reader: :public
    prop :tags, _Array(String), default: -> { [] }, reader: :public

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

    def title_class
      base = "font-semibold text-gray-900"
      (status == :wont_do) ? "#{base} line-through text-gray-500" : base
    end

    def status_label
      status.to_s.tr("_", " ")
    end

    private

    def root_element_attributes
      {
        html_options: {role: "button", tabindex: 0}
      }
    end

    def root_element_classes
      "block cursor-pointer rounded-lg border-2 p-4 shadow-sm transition hover:shadow-md #{class_list_for_stimulus_classes(:status)}"
    end
  end
end

# task_card_component.html.erb
<%= root_element do |card| %>
  <div class="flex items-center justify-between">
    <h3 class="<%= title_class %>"><%= title %></h3>
    <span class="rounded-full bg-white px-2 py-0.5 text-xs font-medium text-gray-700"><%= priority %></span>
  </div>

  <% if tags.any? %>
    <div class="mt-2 flex flex-wrap gap-1">
      <% tags.each do |tag| %>
        <span class="rounded bg-white px-2 py-0.5 text-xs text-gray-600 ring-1 ring-gray-200"><%= tag %></span>
      <% end %>
    </div>
  <% end %>

  <p class="mt-3 text-xs uppercase tracking-wide text-gray-500"><%= status_label %></p>

  <div class="mt-3 flex gap-2">
    <%= card.child_element(
      :button,
      stimulus_action: [:click, :apply],
      stimulus_target: :done_button,
      stimulus_params: {kind: "done"},
      type: "button",
      class: "flex-1 rounded bg-green-600 px-2 py-1 text-xs font-medium text-white hover:bg-green-700 disabled:opacity-50"
    ) { "Mark done" } %>

    <%= card.child_element(
      :button,
      stimulus_action: [:click, :apply],
      stimulus_target: :wont_do_button,
      stimulus_params: {kind: "wont_do"},
      type: "button",
      class: "flex-1 rounded border border-gray-400 px-2 py-1 text-xs font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50"
    ) { "Won't do" } %>
  </div>
<% end %>
