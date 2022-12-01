# frozen_string_literal: true

class GreeterComponent < ViewComponent::Base
  def initialize(cta: "Greet")
    @cta = cta
  end
end
