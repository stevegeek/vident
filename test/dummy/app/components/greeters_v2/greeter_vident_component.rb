# frozen_string_literal: true

module GreetersV2
  class GreeterVidentComponent < ApplicationComponent
    # Lock to V1's identifier so the existing JS controller resolves.
    class << self
      def stimulus_identifier_path = "greeters/greeter_vident_component"
    end

    prop :cta, String, default: "Greet"
  end
end
