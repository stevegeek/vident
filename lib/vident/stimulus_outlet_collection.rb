# frozen_string_literal: true

module Vident
  class StimulusOutletCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      merged = {}
      items.each do |outlet|
        merged.merge!(outlet.to_h)
      end
      merged
    end
  end
end
