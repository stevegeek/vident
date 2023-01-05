# frozen_string_literal: true

# TODO: what about when used with Phlex?
module Vident
  class TestCase < ::ViewComponent::TestCase
    include Vident::Testing::AutoTest
  end
end
