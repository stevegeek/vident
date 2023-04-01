module Vident
  module ViewComponent
    class Base < ::ViewComponent::Base
      include ::Vident::Component

      # Helper to create the main element
      def parent_element(**options)
        @parent_element ||= RootComponent.new(**parent_element_attributes(options))
      end
      alias_method :root, :parent_element
    end
  end
end
