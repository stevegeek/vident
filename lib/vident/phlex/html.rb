# frozen_string_literal: true

module Vident
  module Phlex
    class HTML < ::Phlex::HTML
      include ::Vident::Component

      class << self
        # Phlex uses a DSL to define the document, and those methods could easily clash with our attribute
        # accessors. Therefore in Phlex components we do not create attribute accessors, and instead use instance
        # variables directly.
        def attribute(name, **options)
          options[:delegates] = false
          super
        end
      end

      # Helper to create the main element
      def parent_element(**options)
        @parent_element ||= RootComponent.new(**parent_element_attributes(options))
      end
      alias_method :root, :parent_element
    end
  end
end
