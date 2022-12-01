# frozen_string_literal: true

class GreeterVidentComponent < ViewComponent::Base
  include Vident::Component

  attribute :cta, default: "Greet"
end
