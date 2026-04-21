# frozen_string_literal: true

module PhlexGreetersV2
  class GreeterWithTriggerComponent < ApplicationComponent
    # Lock to V1's identifier so the existing
    # phlex_greeters/greeter_with_trigger_component_controller.js resolves.
    class << self
      def stimulus_identifier_path = "phlex_greeters/greeter_with_trigger_component"
    end

    # Phlex doesn't have `renders_one`, so this class mirrors V1's
    # memoised `trigger` method — a setter-ish pattern that doubles as
    # the slot accessor during render.
    def trigger(**args)
      @trigger ||= GreeterButtonComponent.new(**args)
    end

    private

    def trigger_or_default(greeter)
      return render(@trigger) if @trigger

      # `greeter.stimulus_action(:click, :greet)` parses into a
      # Stimulus::Action value object that the child component accepts
      # as-is through its `stimulus_actions:` prop.
      render(trigger(before_clicked_message: "Greet", stimulus_actions: [greeter.stimulus_action(:click, :greet)]))
    end

    def root_element_attributes
      {
        stimulus_classes: {pre_click: "text-md text-gray-500", post_click: "text-xl text-blue-700"}
      }
    end

    def view_template(&)
      # `vanish(&)` consumes the outer block's content so Phlex doesn't
      # try to render it as children — the trigger slot is configured
      # via the block's side effects, not its output.
      vanish(&)
      root_element do |greeter|
        input(type: "text", data: {**greeter.stimulus_target(:name)}, class: %(shadow appearance-none border rounded py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline))
        trigger_or_default(greeter)
        greeter.child_element(:span, stimulus_target: :output, class: "ml-4 #{greeter.class_list_for_stimulus_classes(:pre_click)}") do
          plain %( ... )
        end
      end
    end
  end
end
