# frozen-string-literal: true

module Vident
  module Typed
    module Phlex
      class HTML < ::Phlex::HTML
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

        # Helper to create the main element
        def parent_element(**options)
          @parent_element ||= ::Vident::Phlex::RootComponent.new(**parent_element_attributes(options))
        end
        alias_method :root, :parent_element
      end
    end
  end
end
