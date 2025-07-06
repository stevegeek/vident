# frozen_string_literal: true

module PhlexGreeters
  class GreeterWithTriggerComponent < ApplicationComponent
    def trigger(**args)
      @trigger ||= GreeterButtonComponent.new(**args)
    end

    private

    def trigger_or_default(greeter)
      return render(@trigger) if @trigger

      trigger(cta: "Greet", stimulus_actions: [greeter.stimulus_action(:click, :greet)])
    end

    def root_element_attributes
      {
        stimulus_classes: {pre_click: "text-md text-gray-500", post_click: "text-xl text-blue-700"}
      }
    end

    def view_template(&)
      vanish(&)
      root_element do |greeter|
        input(type: "text", data: {**greeter.stimulus_target(:name)}, class: %(shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline))
        trigger_or_default(greeter)
        greeter.tag(:span, stimulus_target: :output, class: "ml-4 #{greeter.class_list_for_stimulus_classes(:pre_click)}") do
          plain %( ... )
        end
      end
    end
  end
end
