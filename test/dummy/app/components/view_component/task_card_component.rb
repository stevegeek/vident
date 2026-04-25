# frozen_string_literal: true

require "vident"

module ViewComponent
  class TaskCardComponent < ::Vident::ViewComponent::Base
    # Locked so the Phlex and ViewComponent twins on the docs site share
    # one Stimulus controller identifier and emit equivalent HTML.
    class << self
      def stimulus_identifier_path = "task_card_component"
    end

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
