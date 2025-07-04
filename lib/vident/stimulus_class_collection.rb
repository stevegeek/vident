# frozen_string_literal: true

module Vident
  class StimulusClassCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?
      
      merged = {}
      items.each do |css_class|
        merged.merge!(css_class.to_h)
      end
      merged
    end
  end
end