# frozen_string_literal: true

require "vident2"

module DashboardV2
  # Thin V2 base class. Mirrors Dashboard::ApplicationComponent but
  # inherits from Vident2::Phlex::HTML so every subclass picks up the
  # V2 DSL, resolver, Draft/Plan pipeline, and mutator seam.
  class ApplicationComponent < ::Vident2::Phlex::HTML
    include ::Phlex::Rails::Helpers::Routes
  end
end
