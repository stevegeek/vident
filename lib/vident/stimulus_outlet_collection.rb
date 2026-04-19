# frozen_string_literal: true

module Vident
  class StimulusOutletCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      items.each_with_object({}) { |outlet, merged| merged.merge!(outlet.to_h) }
    end
  end
end
