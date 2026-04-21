# frozen_string_literal: true

module Greeters
  # Vanilla ViewComponent — intentionally does NOT use Vident, so this
  # mirrors the V1 GreeterComponent exactly. Renders a plain greet
  # button + hand-rolled `data-controller="greeter"` attribute.
  class GreeterComponent < ::ViewComponent::Base
    def initialize(cta: "Greet")
      @cta = cta
    end
  end
end
