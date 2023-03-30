# frozen_string_literal: true

module Vident
  module ViewComponent
    class RootComponent < ::ViewComponent::Base
      include ::Vident::RootComponent

      if Gem.loaded_specs.has_key? "better_html"
        begin
          include ::Vident::BetterHtml::RootComponent
        rescue
          raise "if `better_html`` is being used you must install `vident-better_html"
        end
      end

      SELF_CLOSING_TAGS = Set[:area, :base, :br, :col, :embed, :hr, :img, :input, :link, :meta, :param, :source, :track, :wbr].freeze

      def target_tag(tag_name, targets, **options, &block)
        parsed = parse_targets(Array.wrap(targets))
        options[:data] ||= {}
        options[:data].merge!(build_target_data_attributes(parsed))
        content = view_context.capture(&block) if block
        view_context.content_tag(tag_name, content, options)
      end

      def call
        # Generate outer tag options and render
        tag_type = content_tag_type
        options = content_tag_options
        if SELF_CLOSING_TAGS.include?(tag_type)
          view_context.tag(tag_type, options)
        else
          view_context.content_tag(tag_type, content, options)
        end
      end

      private

      def content_tag_options
        options = @html_options&.dup || {}
        data_attrs = tag_data_attributes
        options[:data] = options[:data].present? ? data_attrs.merge(options[:data]) : data_attrs
        return options unless @id
        options.merge(id: @id)
      end

      def content_tag_type
        @element_tag.presence || :div
      end
    end
  end
end
