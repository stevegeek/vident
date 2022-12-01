# frozen_string_literal: true

class HelloVidentComponent < ViewComponent::Base
  include Vident::Component

  attribute :name, default: "World"
end
