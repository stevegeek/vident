# frozen_string_literal: true

class HelloComponent < ViewComponent::Base
  def initialize(name: "World")
    @name = name
  end
end
