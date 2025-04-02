# frozen_string_literal: true

module TypedViewComponent
  class GreeterComponent < ::ViewComponent::Base
    def initialize(cta: "Greet")
      @cta = cta
    end
  end
end
