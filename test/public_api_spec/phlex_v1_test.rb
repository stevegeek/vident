# frozen_string_literal: true

require "test_helper"
require_relative "support"
Dir[File.join(__dir__, "specs", "*.rb")].sort.each { |f| require_relative "specs/#{File.basename(f, ".rb")}" }

module Vident
  module PublicApiSpec
    # Runs the adapter-agnostic spec modules against Vident::Phlex::HTML.
    # When Vident 2.0 lands, clone this file as phlex_v2_test.rb with
    # PhlexV2Adapter swapped in — same spec modules, new implementation.
    class PhlexV1Test < Minitest::Test
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
    end
  end
end
