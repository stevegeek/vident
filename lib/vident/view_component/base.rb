module Vident
  module ViewComponent
    class Base < ::ViewComponent::Base
      include ::Vident::Component

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

      SELF_CLOSING_TAGS = Set[:area, :base, :br, :col, :embed, :hr, :img, :input, :link, :meta, :param, :source, :track, :wbr].freeze

      def root_element(&block)
        tag_type = root_element_tag_type
        child_content = view_context.capture(self, &block) if block # Evaluate before generating the outer tag options to ensure DSL methods are executed
        options = root_element_tag_options
        if SELF_CLOSING_TAGS.include?(tag_type)
          view_context.tag(tag_type, options)
        else
          view_context.content_tag(tag_type, child_content, options)
        end
      end

      def as_stimulus_targets(...)
        # TODO:
      end

      def as_stimulus_target(...)
        # TODO:
      end

      def as_stimulus_actions(...)
        # TODO:
      end

      def as_stimulus_action(...)
        # TODO:
      end

      def as_stimulus_controllers(...)
        # TODO:
      end

      def as_stimulus_controller(...)
        # TODO:
      end

      def as_stimulus_outlets(...)
        # TODO:
      end

      def as_stimulus_outlet(...)
        # TODO:
      end

      def as_stimulus_values(...)
        # TODO:
      end

      def as_stimulus_value(...)
        # TODO:
      end

      def as_stimulus_classes(...)
        # TODO:
      end

      def as_stimulus_class(...)
        # TODO:
      end

      private

      def generate_tag(tag_name, stimulus_data_attributes, options, &block)
        # parsed = parse_targets(Array.wrap(targets))
        # options[:data] ||= {}
        # options[:data].merge!(build_target_data_attributes(parsed))
        # content = view_context.capture(&block) if block
        # view_context.content_tag(tag_name, content, options)
      end

      def root_element_tag_options
        options = @html_options&.dup || {}
        data_attrs = stimulus_data_attributes
        options[:data] = options[:data].present? ? data_attrs.merge(options[:data]) : data_attrs
        return options unless @id
        options.merge(id: @id)
      end

      def root_element_tag_type
        @element_tag.presence&.to_sym || :div
      end
    end
  end
end
