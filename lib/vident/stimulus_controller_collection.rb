# frozen_string_literal: true

module Vident
  class StimulusControllerCollection < StimulusCollectionBase
    def to_h
      return {} if items.empty?
      
      controller_values = items.map(&:to_s).reject(&:empty?)
      return {} if controller_values.empty?
      
      { controller: controller_values.join(" ") }
    end
  end
end