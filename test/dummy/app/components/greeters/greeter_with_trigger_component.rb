# frozen_string_literal: true

module Greeters
  class GreeterWithTriggerComponent < ApplicationComponent
    renders_one :trigger, GreeterButtonComponent

    def root_element_attributes
      {
        stimulus_classes: {
          pre_click: "text-md text-gray-500",
          post_click: "text-xl text-blue-700"
        }
      }
    end
  end
end
