module Vident
  module Typed
    module ViewComponent
      class Base < ::ViewComponent::Base
        include ::Vident::Typed::Component

        # Helper to create the main element
        def parent_element(**options)
          @parent_element ||= ::Vident::ViewComponent::RootComponent.new(**parent_element_attributes(options))
        end
        alias_method :root, :parent_element
      end
    end
  end
end
