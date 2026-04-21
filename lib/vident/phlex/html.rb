# frozen_string_literal: true

require "set"

module Vident
  module Phlex
    class HTML < ::Phlex::HTML
      include ::Vident::Component

      STANDARD_ELEMENTS = %i[
        a abbr address article aside b bdi bdo blockquote body button caption
        cite code colgroup data datalist dd del details dfn dialog div dl dt
        em fieldset figcaption figure footer form g h1 h2 h3 h4 h5 h6 head
        header hgroup html i iframe ins kbd label legend li main map mark
        menuitem meter nav noscript object ol optgroup option output p path
        picture pre progress q rp rt ruby s samp script section select slot
        small span strong style sub summary sup svg table tbody td template_tag
        textarea tfoot th thead time title tr u ul video wbr
      ].freeze
      VOID_ELEMENTS = %i[area br embed hr img input link meta param source track col].freeze
      VALID_TAGS = Set[*(STANDARD_ELEMENTS + VOID_ELEMENTS)].freeze

      class << self
        # Walks caller_locations to skip the `inherited` frame itself.
        def inherited(subclass)
          loc = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0]
          subclass.component_source_file_path = loc&.path
          super
        end

        attr_accessor :component_source_file_path

        def cache_component_modified_time
          path = component_source_file_path
          raise ::Vident::ConfigurationError, "No component source file exists #{path}" unless path && ::File.exist?(path)
          ::File.mtime(path).to_i.to_s
        end
      end

      # DSL procs stay unresolved until `helpers` is wired; resolve them here.
      def before_template
        resolve_stimulus_attributes_at_render_time
        super
      end

      # Capture block first so children can mutate this Draft before it seals (outlet-host pattern).
      def root_element(**overrides, &block)
        tag_type = root_element_tag_type
        check_valid_html_tag!(tag_type)
        if block
          content = capture(self, &block).html_safe
          options = build_root_element_attributes(overrides)
          send(tag_type, **options) { content }
        else
          options = build_root_element_attributes(overrides)
          send(tag_type, **options)
        end
      end

      private

      def check_valid_html_tag!(tag_name)
        return if VALID_TAGS.include?(tag_name)
        raise ArgumentError,
          "Unsupported HTML tag name #{tag_name}. Valid tags are: #{VALID_TAGS.to_a.join(", ")}"
      end

      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        check_valid_html_tag!(tag_name)
        options[:data] ||= {}
        options[:data].merge!(stimulus_data_attributes)
        send(tag_name, **options, &block)
      end
    end
  end
end
