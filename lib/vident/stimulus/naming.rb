# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module Vident
  module Stimulus
    module Naming
      module_function

      def stimulize_path(path)
        path.to_s.split("/").map(&:dasherize).join("--")
      end

      def js_name(name)
        name.to_s.camelize(:lower)
      end
    end
  end
end
