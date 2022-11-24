# frozen_string_literal: true

module Vident
  module Attributes
    module Types
      include ::Dry.Types

      StrippedString = Types::String.constructor(&:strip)
      BooleanDefaultFalse = Types::Bool.default(false)
      BooleanDefaultTrue = Types::Bool.default(true)
      HashDefaultEmpty = Types::Hash.default({}.freeze)
    end
  end
end
