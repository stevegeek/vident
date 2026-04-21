# frozen_string_literal: true

module Vident2
  module Stimulus
    # Sentinel that serialises to the literal string "null". Use in
    # `value` / `param` positions where the Stimulus side expects a
    # JSON-parsed JS `null` (Object / Array value types).
    #
    # A bare `nil` drops the attribute entirely. Reach for Null only when
    # you need an explicit `"null"` in the emitted HTML.
    Null = Object.new
    def Null.inspect = "Vident2::Stimulus::Null"
    def Null.to_s = "null"
    Null.freeze
  end
end
