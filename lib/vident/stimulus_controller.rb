# frozen_string_literal: true

module Vident
  class StimulusController < StimulusAttributeBase
    attr_reader :path, :name

    def to_s = name

    def data_attribute_name = "controller"

    def data_attribute_value = name

    private

    # `@implied_controller` on this class is a raw path String (not a
    # StimulusController instance as on the base), so the base class's
    # `.path` / `.name` accessors don't apply and we override.
    def implied_controller_path
      raise ArgumentError, "implied_controller is required to get implied controller path" unless @implied_controller
      @implied_controller
    end

    def implied_controller_name
      raise ArgumentError, "implied_controller is required to get implied controller name" unless @implied_controller
      stimulize_path(@implied_controller)
    end

    def parse_arguments(*args)
      case args.size
      when 0
        @path = implied_controller_path
        @name = implied_controller_name
      when 1
        @path = args[0].to_s
        @name = stimulize_path(@path)
      else
        raise ArgumentError, "Invalid number of arguments: #{args.size}. Expected 0 or 1 argument."
      end
    end
  end
end
