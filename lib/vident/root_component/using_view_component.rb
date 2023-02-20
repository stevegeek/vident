# frozen_string_literal: true

if Gem.loaded_specs.has_key? "view_component"
  require "view_component"

  module Vident
    module RootComponent
      class UsingViewComponent < ::ViewComponent::Base
        include Base

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
          options.merge(id: @id) if @id
        end

        def content_tag_type
          @element_tag.presence || :div
        end
      end
    end
  end
end
