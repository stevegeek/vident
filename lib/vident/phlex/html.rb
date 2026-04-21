# frozen_string_literal: true

module Vident
  module Phlex
    class HTML < ::Phlex::HTML
      include Vident::Component

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

        # Include the matching `Phlex::Rails::Helpers::<CamelCase>` module for
        # each Rails helper name. Replaces `helpers.foo(...)` with bare `foo(...)`
        # calls via phlex-rails' adapter macros.
        #
        #   class Card < Vident::Phlex::HTML
        #     phlex_helpers :number_with_precision, :t, :l
        #   end
        def phlex_helpers(*helper_names)
          helper_names.each do |name|
            mod_name = name.to_s.camelize
            mod = begin
              ::Phlex::Rails::Helpers.const_get(mod_name)
            rescue NameError
              raise ArgumentError, "No Phlex::Rails::Helpers::#{mod_name} adapter. See https://www.phlex.fun/rails/helpers for the available list."
            end
            include(mod)
          end
        end
      end

      # Helper to create the main element
      def root_element(**overrides, &block)
        tag_type = root_element_tag_type
        check_valid_html_tag!(tag_type)
        # Evaluate block first so DSL methods run before outer tag options are computed.
        if block_given?
          content = capture(self, &block).html_safe
          options = resolve_root_element_attributes_before_render(overrides)
          send(tag_type, **options) { content }
        else
          send(tag_type, **resolve_root_element_attributes_before_render(overrides))
        end
      end

      # Phlex lifecycle hook: resolve stimulus DSL procs now that the view
      # context is wired (so `helpers` / `view_context` work inside them).
      def before_template(&)
        resolve_stimulus_attributes_at_render_time
        super
      end

      private

      def check_valid_html_tag!(tag_name)
        unless VALID_TAGS.include?(tag_name)
          raise ArgumentError, "Unsupported HTML tag name #{tag_name}. Valid tags are: #{VALID_TAGS.to_a.join(", ")}"
        end
      end

      def generate_child_element(tag_type, stimulus_data_attributes, options, &block)
        options[:data] ||= {}
        options[:data].merge!(stimulus_data_attributes)
        check_valid_html_tag!(tag_type)
        send(tag_type, **options, &block)
      end
    end
  end
end
