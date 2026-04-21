# frozen_string_literal: true

module Vident
  module Capabilities
    module Inspectable
      # Matches the Data.define#with convention introduced in Ruby 3.2.
      def with(overrides = {})
        self.class.new(**to_h.merge(overrides))
      end

      def inspect(klass_name = "Component")
        attr_text = to_h.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
        "#<#{self.class.name}<Vident::#{klass_name}> #{attr_text}>"
      end
    end
  end
end
