# frozen_string_literal: true

module Vident
  class StimulusValueCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      merged = {}
      items.each do |value|
        merged.merge!(value.to_h)
      end
      merged
    end
  end
end
