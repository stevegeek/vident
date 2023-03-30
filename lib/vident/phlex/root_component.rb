# frozen_string_literal: true

module Vident
  module Phlex
    class RootComponent < ::Phlex::HTML
      include ::Vident::RootComponent

      if Gem.loaded_specs.has_key? "better_html"
        begin
          include ::Vident::BetterHtml::RootComponent
        rescue
          raise "if `better_html`` is being used you must install `vident-better_html"
        end
      end

      STANDARD_ELEMENTS = [:a, :abbr, :address, :article, :aside, :b, :bdi, :bdo, :blockquote, :body, :button, :caption, :cite, :code, :colgroup, :data, :datalist, :dd, :del, :details, :dfn, :dialog, :div, :dl, :dt, :em, :fieldset, :figcaption, :figure, :footer, :form, :g, :h1, :h2, :h3, :h4, :h5, :h6, :head, :header, :hgroup, :html, :i, :iframe, :ins, :kbd, :label, :legend, :li, :main, :map, :mark, :menuitem, :meter, :nav, :noscript, :object, :ol, :optgroup, :option, :output, :p, :path, :picture, :pre, :progress, :q, :rp, :rt, :ruby, :s, :samp, :script, :section, :select, :slot, :small, :span, :strong, :style, :sub, :summary, :sup, :svg, :table, :tbody, :td, :template_tag, :textarea, :tfoot, :th, :thead, :time, :title, :tr, :u, :ul, :video, :wbr].freeze
      VOID_ELEMENTS = [:area, :br, :embed, :hr, :img, :input, :link, :meta, :param, :source, :track, :col].freeze

      VALID_TAGS = Set[*(STANDARD_ELEMENTS + VOID_ELEMENTS)].freeze

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
