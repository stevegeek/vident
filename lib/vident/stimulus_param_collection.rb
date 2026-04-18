# frozen_string_literal: true

module Vident
  class StimulusParamCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      merged = {}
      items.each do |param|
        merged.merge!(param.to_h)
      end
      merged
    end
  end
end
