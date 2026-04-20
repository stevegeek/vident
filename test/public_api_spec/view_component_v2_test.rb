# frozen_string_literal: true

require "test_helper"
require "vident2"
require_relative "support"
Dir[File.join(__dir__, "specs", "*.rb")].sort.each { |f| require_relative "specs/#{File.basename(f, ".rb")}" }

module Vident
  module PublicApiSpec
    # Runs the adapter-agnostic spec modules (+ VC-only VcAsStimulus)
    # against Vident2::ViewComponent::Base. Red baseline at Phase 2
    # start; progressively greens as features land.
    class ViewComponentV2Test < ::ViewComponent::TestCase
      include ViewComponentV2Adapter
      include CoreDSL
      include Mutators
      include Controllers
      include Serialization
      include Introspection
      include ScopedEvents
      include Outlets
      include RootElement
      include Inheritance
      include Props
      include InstanceParsers
      include ChildElement
      include StableId
      include ClassList
      include Caching
      include DslAdvanced
      include Errors
      include VcAsStimulus
      include V2GotchaFixes
    end
  end
end
