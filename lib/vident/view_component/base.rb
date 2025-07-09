module Vident
  module ViewComponent
    class Base < ::ViewComponent::Base
      include ::Vident::Component

      class << self
        def cache_component_modified_time
          cache_sidecar_view_modified_time + cache_rb_component_modified_time
        end

        def cache_sidecar_view_modified_time
          ::File.exist?(template_path) ? ::File.mtime(template_path).to_i.to_s : ""
        end

        def cache_rb_component_modified_time
          ::File.exist?(component_path) ? ::File.mtime(component_path).to_i.to_s : ""
        end

        def template_path
          # Check for common ViewComponent template extensions in order of preference
          extensions = [".html.erb", ".erb", ".html.haml", ".haml", ".html.slim", ".slim"]
          base_path = Rails.root.join(components_base_path, virtual_path)

          extensions.each do |ext|
            potential_path = "#{base_path}#{ext}"
            return potential_path if File.exist?(potential_path)
          end

          # Return the default .html.erb path if no template is found
          Rails.root.join(components_base_path, "#{virtual_path}.html.erb").to_s
        end

        def component_path
          Rails.root.join(components_base_path, "#{virtual_path}.rb").to_s
        end

        def components_base_path
          ::Rails.configuration.view_component.view_component_path || "app/components"
        end
      end

      SELF_CLOSING_TAGS = Set[:area, :base, :br, :col, :embed, :hr, :img, :input, :link, :meta, :param, :source, :track, :wbr].freeze

      def root_element(**overrides, &block)
        tag_type = root_element_tag_type
        child_content = view_context.capture(self, &block) if block_given? # Evaluate before generating the outer tag options to ensure DSL methods are executed
        options = resolve_root_element_attributes_before_render(overrides)
        if SELF_CLOSING_TAGS.include?(tag_type)
          view_context.tag(tag_type, options)
        else
          view_context.content_tag(tag_type, child_content, options)
        end
      end

      def as_stimulus_targets(...)
        to_data_attribute_string(**stimulus_targets(...))
      end

      def as_stimulus_target(...)
        to_data_attribute_string(**stimulus_target(...))
      end

      def as_stimulus_actions(...)
        to_data_attribute_string(**stimulus_actions(...))
      end

      def as_stimulus_action(...)
        to_data_attribute_string(**stimulus_action(...))
      end

      def as_stimulus_controllers(...)
        to_data_attribute_string(**stimulus_controllers(...))
      end

      def as_stimulus_controller(...)
        to_data_attribute_string(**stimulus_controller(...))
      end

      def as_stimulus_outlets(...)
        to_data_attribute_string(**stimulus_outlets(...))
      end

      def as_stimulus_outlet(...)
        to_data_attribute_string(**stimulus_outlet(...))
      end

      def as_stimulus_values(...)
        to_data_attribute_string(**stimulus_values(...))
      end

      def as_stimulus_value(...)
        to_data_attribute_string(**stimulus_value(...))
      end

      def as_stimulus_classes(...)
        to_data_attribute_string(**stimulus_classes(...))
      end

      def as_stimulus_class(...)
        to_data_attribute_string(**stimulus_class(...))
      end

      private

      def generate_tag(tag_name, stimulus_data_attributes, options, &block)
        options[:data] ||= {}
        options[:data].merge!(stimulus_data_attributes)
        view_context.content_tag(tag_name, options, &block)
      end

      def escape_attribute_name_for_html(name)
        name.to_s.gsub(/[^a-zA-Z0-9\-_]/, "").tr("_", "-")
      end

      def escape_attribute_value_for_html(value)
        value.to_s.gsub('"', "&quot;").gsub("'", "&#39;")
      end

      def to_data_attribute_string(**attributes)
        attributes.map { |key, value| "data-#{escape_attribute_name_for_html(key)}=\"#{escape_attribute_value_for_html(value)}\"" }
          .join(" ")
          .html_safe
      end
    end
  end
end
