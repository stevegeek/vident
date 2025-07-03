# frozen_string_literal: true

module Greeters
  class GreeterVidentComponent < ApplicationComponent
    prop :cta, String, default: "Greet"
  end
end
