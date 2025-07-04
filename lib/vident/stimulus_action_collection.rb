# frozen_string_literal: true

module Vident
  class StimulusActionCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?
      
      { action: items.map(&:to_s).join(" ") }
    end
  end
end