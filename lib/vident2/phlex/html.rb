# frozen_string_literal: true

require "set"

module Vident2
  module Phlex
    class HTML < ::Phlex::HTML
      include ::Vident2::Component

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
        # Capture the subclass's defining `.rb` path at class-definition
        # time so Caching#cache_component_modified_time can read its mtime.
        # Walks caller_locations to skip the `inherited` frame itself.
        def inherited(subclass)
          loc = caller_locations(1, 10).reject { |l| l.label == "inherited" }[0]
          subclass.component_source_file_path = loc&.path
          super
        end

        attr_accessor :component_source_file_path

        def cache_component_modified_time
          path = component_source_file_path
          raise StandardError, "No component source file exists #{path}" unless path && ::File.exist?(path)
          ::File.mtime(path).to_i.to_s
        end
      end

      # Phlex lifecycle hook: resolve stimulus DSL procs now that
      # `view_context` / `helpers` are wired. Procs declared in the DSL
      # stayed unresolved at `after_initialize`; this is where they run.
      def before_template
        resolve_stimulus_attributes_at_render_time
        super
      end

      # Block-capture-first so children initialising inside the block can
      # mutate THIS instance's Draft (outlet-host pattern). After the
      # block returns, we seal the Draft and emit the tag.
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

      # Phlex tag DSL emits open-close pairs for non-void tags and
      # self-closing for void tags automatically, so we just forward.
      def generate_child_element(tag_name, stimulus_data_attributes, options, &block)
        check_valid_html_tag!(tag_name)
        options[:data] ||= {}
        options[:data].merge!(stimulus_data_attributes)
        send(tag_name, **options, &block)
      end
    end
  end
end
