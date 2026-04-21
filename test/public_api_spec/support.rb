# frozen_string_literal: true

require "cgi"

module Vident
  module PublicApiSpec
    # Each adapter module contributes:
    #   - #component_base        : the adapter's Vident base class
    #   - #define_component(...) : build a named anonymous subclass
    #   - #render(instance)      : render the component to an HTML string
    #
    # Adapter modules are included into concrete test classes alongside spec
    # modules, so the same spec tests run unmodified against both adapters.
    #
    # SPEC-NOTE (HTML entity encoding): Phlex emits `>` and `&` raw in
    # attribute values; ViewComponent's `content_tag` emits `&gt;` and
    # `&amp;`. Browsers decode both to the same semantic content. The spec
    # suite asserts on semantic attribute values, so `#render` applies
    # `CGI.unescapeHTML` before returning. If a per-adapter test needs to
    # check literal encoded bytes, it can call `#render_raw` instead.

    module PhlexAdapter
      def component_base = ::Vident::Phlex::HTML

      # Build a Vident::Phlex::HTML subclass whose .name returns the given
      # string (drives stimulus_identifier_path and therefore the implied
      # controller, emitted class on root, etc.). If no view_template is
      # defined, a default `root_element` one is installed so empty-body
      # specs still render.
      def define_component(name: "TestComponent", &block)
        klass = Class.new(component_base)
        klass.define_singleton_method(:name) { name }
        klass.class_eval(&block) if block
        unless klass.instance_methods(false).include?(:view_template)
          klass.define_method(:view_template) { root_element }
        end
        klass
      end

      # Install an adapter-appropriate render method. The given block's
      # self is a component instance. For Phlex it becomes `view_template`.
      def define_render(klass, &block)
        klass.define_method(:view_template) { instance_exec(&block) }
      end

      def render_raw(component) = component.call.to_s

      def render(component) = CGI.unescapeHTML(render_raw(component))
    end

    module ViewComponentAdapter
      def component_base = ::Vident::ViewComponent::Base

      def define_component(name: "TestComponent", &block)
        klass = Class.new(component_base)
        klass.define_singleton_method(:name) { name }
        klass.class_eval(&block) if block
        unless klass.instance_methods(false).include?(:call)
          klass.define_method(:call) { root_element }
        end
        klass
      end

      def define_render(klass, &block)
        klass.define_method(:call) { instance_exec(&block) }
      end

      # Uses ViewComponent::TestCase#render_inline (test class must
      # inherit from it) to get a view_context.
      def render_raw(component)
        render_inline(component)
        rendered_content.to_s
      end

      def render(component) = CGI.unescapeHTML(render_raw(component))
    end
  end
end
