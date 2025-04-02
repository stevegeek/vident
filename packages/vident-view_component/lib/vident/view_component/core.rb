module Vident
  module ViewComponent
    class Core < ::ViewComponent::Base
      class << self
        def current_component_modified_time
          sidecar_view_modified_time + rb_component_modified_time
        end

        def sidecar_view_modified_time
          ::File.exist?(template_path) ? ::File.mtime(template_path).to_i.to_s : ""
        end

        def rb_component_modified_time
          ::File.exist?(component_path) ? ::File.mtime(component_path).to_i.to_s : ""
        end

        def template_path
          File.join components_base_path, "#{virtual_path}.html.erb"
        end

        def component_path
          File.join components_base_path, "#{virtual_path}.rb"
        end

        def components_base_path
          ::Rails.configuration.view_component.view_component_path || "app/components"
        end
      end

      # Helper to create the main element
      def parent_element(**options)
        @parent_element ||= ::Vident::ViewComponent::RootComponent.new(**parent_element_attributes(options))
      end
      alias_method :root, :parent_element
    end
  end
end
