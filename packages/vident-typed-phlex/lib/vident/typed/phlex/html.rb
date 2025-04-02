# frozen-string-literal: true

module Vident
  module Typed
    module Phlex
      class HTML < ::Vident::Phlex::Core
        include ::Vident::Typed::Component

        class << self
          # Phlex uses a DSL to define the document, and those methods could easily clash with our attribute
          # accessors. Therefore in Phlex components we do not create attribute accessors, and instead use instance
          # variables directly.
          def attribute(name, signature = :any, **options, &converter)
            options[:delegates] = false
            super
          end
        end
      end
    end
  end
end
