# frozen_string_literal: true

module Vident
  module Phlex
    class Core < ::Phlex::HTML
      class << self
        def inherited(subclass)
          subclass.component_source_file_path = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].path
          super
        end

        attr_accessor :component_source_file_path

        # Caching support
        def current_component_modified_time
          path = component_source_file_path
          raise StandardError, "No component source file exists #{path}" unless path && ::File.exist?(path)
          ::File.mtime(path).to_i.to_s
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
