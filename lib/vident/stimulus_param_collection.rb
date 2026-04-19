# frozen_string_literal: true

module Vident
  class StimulusParamCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      items.each_with_object({}) { |param, merged| merged.merge!(param.to_h) }
    end
  end
end
