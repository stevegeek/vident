# frozen_string_literal: true

require "test_helper"

class Vident::TestCaseTest < Vident::TestCase
  auto_test(
    TestAttributesComponent,
    url: {
      valid: ["https://cataas.com/cat/says/hello", nil],
      invalid: [""]
    },
    initials: {
      valid: ["A", "AB", "A B"],
      invalid: ["", 123, nil]
    },
    name: {
      valid: {type: String, default: "World"}
    }
  )
end
