module Vident
  module ViewComponent
    class Base < ::ViewComponent::Base
      include ::Vident::Component

      # Helper to create the main element
      def parent_element(**options)
        @parent_element ||= begin
          element_attrs = options
            .except(:id, :element_tag, :html_options, :controller, :controllers, :actions, :targets, :named_classes, :data_maps)
            .merge(
              stimulus_options_for_component(options)
            )
          RootComponent.new(**element_attrs)
        end
      end
      alias_method :root, :parent_element
    end
  end
end
