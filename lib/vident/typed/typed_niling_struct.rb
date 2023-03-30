# frozen_string_literal: true

module Vident
  module Typed
    # A dry struct that is loose about keys provided on initialization. It sets them to nil if not provided.
    # It is strict about types but not about provided keys
    class TypedNilingStruct < ::Dry::Struct
      # convert string keys to symbols
      transform_keys(&:to_sym)

      # resolve default types on nil
      transform_types do |type|
        if type.default?
          type.constructor { |value| value.nil? ? ::Dry::Types::Undefined : value }
        else
          type
        end
      end

      class << self
        def check_schema_duplication(new_keys)
          # allow overriding keys
        end
      end
    end
  end
end
