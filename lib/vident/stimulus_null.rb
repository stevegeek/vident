# frozen_string_literal: true

module Vident
  # Sentinel: emits the literal string "null" as the data attribute value.
  # For Stimulus `Object` and `Array` value types this is JSON-parsed to JS `null`;
  # other value types will read it as garbage ("null" string / NaN / truthy), so only
  # use this with nullable Object/Array values.
  #
  # A bare `nil` (static or returned from a proc) omits the attribute entirely so
  # Stimulus uses its per-type default. Reach for this sentinel only when you need
  # an explicit JS `null`.
  StimulusNull = Object.new
  def StimulusNull.inspect
    "Vident::StimulusNull"
  end

  def StimulusNull.to_s
    "null"
  end
  StimulusNull.freeze
end
