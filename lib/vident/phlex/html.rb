# frozen_string_literal: true

module Vident
  module Phlex
    class HTML < ::Phlex::HTML
      include ::Vident::Component

      STANDARD_ELEMENTS = [:a, :abbr, :address, :article, :aside, :b, :bdi, :bdo, :blockquote, :body, :button, :caption, :cite, :code, :colgroup, :data, :datalist, :dd, :del, :details, :dfn, :dialog, :div, :dl, :dt, :em, :fieldset, :figcaption, :figure, :footer, :form, :g, :h1, :h2, :h3, :h4, :h5, :h6, :head, :header, :hgroup, :html, :i, :iframe, :ins, :kbd, :label, :legend, :li, :main, :map, :mark, :menuitem, :meter, :nav, :noscript, :object, :ol, :optgroup, :option, :output, :p, :path, :picture, :pre, :progress, :q, :rp, :rt, :ruby, :s, :samp, :script, :section, :select, :slot, :small, :span, :strong, :style, :sub, :summary, :sup, :svg, :table, :tbody, :td, :template_tag, :textarea, :tfoot, :th, :thead, :time, :title, :tr, :u, :ul, :video, :wbr].freeze
      VOID_ELEMENTS = [:area, :br, :embed, :hr, :img, :input, :link, :meta, :param, :source, :track, :col].freeze
      VALID_TAGS = Set[*(STANDARD_ELEMENTS + VOID_ELEMENTS)].freeze

      class << self
        def inherited(subclass)
          subclass.component_source_file_path = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0].path
          super
        end

        attr_accessor :component_source_file_path

        # Caching support
        def cache_component_modified_time
          path = component_source_file_path
          raise StandardError, "No component source file exists #{path}" unless path && ::File.exist?(path)
          ::File.mtime(path).to_i.to_s
        end
      end

      # Helper to create the main element
      def root_element(&block)
        tag_type = root_element_tag_type
        content = capture(self, &block) if block_given? # Evaluate before generating the outer tag options to ensure DSL methods are executed
        options = root_element_tag_options
        check_valid_html_tag!(tag_type)
        block = proc { raw content } if content
        send(tag_type, **options, &block)
      end

      private

      def check_valid_html_tag!(tag_name)
        unless VALID_TAGS.include?(tag_name)
          raise ArgumentError, "Unsupported HTML tag name #{tag_name}. Valid tags are: #{VALID_TAGS.to_a.join(", ")}"
        end
      end

      def generate_tag(tag_type, stimulus_data_attributes, options, &block)
        options[:data] ||= {}
        options[:data].merge!(stimulus_data_attributes)
        check_valid_html_tag!(tag_type)
        send(tag_type, **options, &block)
      end
    end
  end
end
