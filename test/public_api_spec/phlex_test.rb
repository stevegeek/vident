# frozen_string_literal: true

require "test_helper"
require "vident"
require_relative "support"
Dir[File.join(__dir__, "specs", "*.rb")].sort.each { |f| require_relative "specs/#{File.basename(f, ".rb")}" }

module Vident
  module PublicApiSpec
    # Runs the adapter-agnostic spec modules against Vident::Phlex::HTML.
    # Phase 2 starts with this class observing massive red — Vident is
    # an empty stub. Features land progressively (tasks 21-25); this
    # suite going green is the acceptance gate for 2.0.
    class PhlexTest < Minitest::Test
      include PhlexAdapter
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
      include GotchaFixes
      include RootElementHelpers
    end
  end
end
