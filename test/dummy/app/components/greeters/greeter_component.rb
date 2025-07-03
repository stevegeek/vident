# frozen_string_literal: true

module Greeters
  # GreeterComponent is a simple component that can be used to greet users. It does not use vident in this example.
  class GreeterComponent < ::ViewComponent::Base
    def initialize(cta: "Greet")
      @cta = cta
    end
  end
end
