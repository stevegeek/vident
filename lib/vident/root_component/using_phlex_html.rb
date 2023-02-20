# frozen_string_literal: true

if Gem.loaded_specs.has_key? "phlex"
  require "phlex"

  module Vident
    module RootComponent
      class UsingPhlexHTML < Phlex::HTML
        include Base
        if Gem.loaded_specs.has_key? "better_html"
          include UsingBetterHTML
        end

        VALID_TAGS = Set[*(Phlex::HTML::VOID_ELEMENTS.keys + Phlex::HTML::STANDARD_ELEMENTS.keys)].freeze

        # Create a tag for a target with a block containing content
        def target_tag(tag_name, targets, **options, &block)
          parsed = parse_targets(Array.wrap(targets))
          options[:data] ||= {}
          options[:data].merge!(build_target_data_attributes(parsed))
          generate_tag(tag_name, **options, &block)
        end

        # Build a tag with the attributes determined by this components properties and stimulus
        # data attributes.
        def template(&block)
          # Generate tag options and render
          tag_type = @element_tag.presence&.to_sym || :div
          raise ArgumentError, "Unsupported HTML tag name #{tag_type}" unless VALID_TAGS.include?(tag_type)
          options = @html_options&.dup || {}
          data_attrs = tag_data_attributes
          data_attrs = options[:data].present? ? data_attrs.merge(options[:data]) : data_attrs
          options = options.merge(id: @id) if @id
          options.except!(:data)
          options.merge!(data_attrs.transform_keys { |k| "data-#{k}" })
          generate_tag(tag_type, **options, &block)
        end

        private

        def generate_tag(tag_type, **options, &block)
          send((tag_type == :template) ? :template_tag : tag_type, **options, &block)
        end
      end
    end
  end
end
