# frozen_string_literal: true

module Vident
  class StimulusTargetCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      merged = {}
      items.each do |target|
        target.to_h.each do |key, value|
          merged[key] = if merged.key?(key)
            # Merge space-separated values for same target attribute
            "#{merged[key]} #{value}"
          else
            value
          end
        end
      end
      merged
    end
  end
end
