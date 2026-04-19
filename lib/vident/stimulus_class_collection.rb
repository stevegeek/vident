# frozen_string_literal: true

module Vident
  class StimulusClassCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?

      items.each_with_object({}) { |css_class, merged| merged.merge!(css_class.to_h) }
    end
  end
end
