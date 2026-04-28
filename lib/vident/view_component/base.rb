# frozen_string_literal: true

require "set"

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
          extensions = [".html.erb", ".erb", ".html.haml", ".haml", ".html.slim", ".slim"]
          base_path = Rails.root.join(components_base_path, virtual_path)

          extensions.each do |ext|
            potential_path = "#{base_path}#{ext}"
            return potential_path if File.exist?(potential_path)
          end

          Rails.root.join(components_base_path, "#{virtual_path}.html.erb").to_s
        end

        def component_path
          Rails.root.join(components_base_path, "#{virtual_path}.rb").to_s
        end

        def components_base_path
          ::Rails.configuration.view_component.view_component_path || "app/components"
        end
      end

      SELF_CLOSING_TAGS = Set[*%i[area base br col embed hr img input link meta param source track wbr]].freeze

      # DSL procs stay unresolved until `@view_context` is set; resolve them here.
      def before_render
        resolve_stimulus_attributes_at_render_time
        super
      end

      # Fragment-cache the block's rendered String using the Vident-computed
      # `cache_key`. Useful inside a `call` method; for sidecar ERB templates
      # use the native `<% cache cache_key do %>` pattern instead.
      def cache_component(*extra_keys, expires_in: nil, &block)
        unless respond_to?(:cacheable?) && cacheable?
          raise ::Vident::ConfigurationError,
            "#{self.class.name} is not cacheable — `include Vident::Caching` and declare `with_cache_key` first."
        end
        ::Rails.cache.fetch([cache_key, *extra_keys], expires_in: expires_in) { capture(&block) }
      end

      # Capture block first so children can mutate this Draft before it seals (outlet-host pattern).
      def root_element(**overrides, &block)
        tag_type = root_element_tag_type
        child_content = view_context.capture(self, &block) if block
        options = build_root_element_attributes(overrides)
        if SELF_CLOSING_TAGS.include?(tag_type)
          view_context.tag(tag_type, options)
        else
          view_context.content_tag(tag_type, child_content, options)
        end
      end

      private

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        options[:data] ||= {}
        options[:data].merge!(stimulus_data_attributes)
        if SELF_CLOSING_TAGS.include?(tag_name.to_sym)
          view_context.tag(tag_name, options)
        elsif block
          view_context.content_tag(tag_name, view_context.capture(&block), options)
        else
          view_context.content_tag(tag_name, nil, options)
        end
      end
    end
  end
end
