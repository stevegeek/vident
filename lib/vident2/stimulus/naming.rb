# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Vident2
  module Stimulus
    # Pure naming helpers shared across value classes. No state, no
    # inheritance — the v1 `StimulusAttributeBase` tree goes away in V2;
    # each value class is a `Literal::Data` and just calls these module
    # functions directly.
    module Naming
      module_function

      # `"admin/users"` -> `"admin--users"`. Symbol or String accepted.
      def stimulize_path(path)
        path.to_s.split("/").map(&:dasherize).join("--")
      end

      # `:my_thing` -> `"myThing"`. Used for action method names and
      # target names (not for attribute keys, which dasherize instead).
      def js_name(name)
        name.to_s.camelize(:lower)
      end
    end
  end
end
