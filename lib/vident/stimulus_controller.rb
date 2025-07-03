# frozen_string_literal: true

module Vident
  class StimulusController < StimulusAttribute
    attr_reader :path, :name

    def to_s
      name
    end

    def data_attribute_name
      "controller"
    end

    def data_attribute_value
      name
    end

    private

    def implied_controller_path
      @implied_controller
    end

    def implied_controller_name
      stimulize_path(@implied_controller)
    end

    def parse_arguments(*args)
      case args.size
      when 0
        # No arguments: use implied controller path
        @path = implied_controller_path
        @name = implied_controller_name
      when 1
        # Single argument: controller path
        @path = args[0]
        @name = stimulize_path(args[0])
      else
        raise ArgumentError, "Invalid number of arguments: #{args.size}. Expected 0 or 1 argument."
      end
    end
  end
end