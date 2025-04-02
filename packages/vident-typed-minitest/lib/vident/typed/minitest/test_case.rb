# frozen_string_literal: true

# TODO: what about when used with Phlex?
module Vident
  module Typed
    module Minitest
      class TestCase < ::ViewComponent::TestCase
        include AutoTest
      end
    end
  end
end
