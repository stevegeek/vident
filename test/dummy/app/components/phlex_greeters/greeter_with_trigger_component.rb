# frozen_string_literal: true

module PhlexGreeters
  class GreeterWithTriggerComponent < ApplicationComponent
    include Phlex::DeferredRender

    def trigger(**args)
      @trigger ||= GreeterButtonComponent.new(**args)
    end

    private

    def trigger_or_default(greeter)
      return render(@trigger) if @trigger

      trigger(cta: "Greet", actions: [greeter.action(:click, :greet)])
    end

    def root_element_attributes
      {
        named_classes: {pre_click: "text-md text-gray-500", post_click: "text-xl text-blue-700"}
      }
    end

    def view_template
      render root do |greeter|
        input(type: "text", data: greeter.target_data_attribute(:name), class: %(shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline))
        trigger_or_default(greeter)
        greeter.target_tag(:span, :output, class: "ml-4 #{greeter.named_classes(:pre_click)}") do
          plain %( ... )
        end
      end
    end
  end
end
