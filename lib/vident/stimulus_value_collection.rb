# frozen_string_literal: true

module Vident
  class StimulusValueCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      items.each_with_object({}) { |value, merged| merged.merge!(value.to_h) }
    end
  end
end
