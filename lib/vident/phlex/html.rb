# frozen-string-literal: true

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
