# frozen_string_literal: true

if Gem.loaded_specs.has_key? "phlex"
  require "phlex"

  module Vident
    module RootComponent
      class PhlexHTML < Phlex::HTML
        include Base
        # Build a tag with the attributes determined by this components properties and stimulus
        # data attributes.
        def template(&block)
          # Generate tag options and render
          tag_type = @element_tag.presence || :div
          options = @html_options&.dup || {}
          data_attrs = tag_data_attributes
          data_attrs = options[:data].present? ? data_attrs.merge(options[:data]) : data_attrs
          options = options.merge(id: @id) if @id
          options.except!(:data)
          options.merge!(data_attrs.transform_keys { |k| "data-#{k}" })
          send(tag_type, **options, &block)
        end
      end
    end
  end
end
