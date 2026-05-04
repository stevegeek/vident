# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "base"
require_relative "controller"
require_relative "selector"

module Vident
  module Stimulus
    # `data-<parent-ctrl>-<child-ctrl>-outlet` fragment.
    class Outlet < Base
      prop :controller, Controller
      prop :name, String
      prop :selector, String

      # Characters that only make sense in a CSS selector, never in a
      # Stimulus controller path/identifier.
      SELECTOR_CHARS = /[.#\[>,*+:]/

      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Outlet => o]
          o
        in [Symbol => sym]
          name = sym.to_s.dasherize
          new(controller: implied, name: name, selector: auto_selector(name, component_id: component_id))
        in [String => str] if SELECTOR_CHARS.match?(str)
          raise ::Vident::ParseError, raw_string_selector_message(str)
        in [String => str]
          name = Naming.stimulize_path(str)
          new(controller: implied, name: name, selector: auto_selector(name, component_id: component_id))
        in [Symbol => sym, Selector => sel]
          new(controller: implied, name: sym.to_s.dasherize, selector: sel.css)
        in [String => str, Selector => sel]
          new(controller: implied, name: Naming.stimulize_path(str), selector: sel.css)
        in [String => parent_path, Symbol => child_sym]
          child_name = child_sym.to_s.dasherize
          new(
            controller: Controller.parse(parent_path, implied: implied),
            name: child_name,
            selector: auto_selector(child_name, component_id: component_id)
          )
        in [String => parent_path, Symbol => child_sym, Selector => sel]
          new(
            controller: Controller.parse(parent_path, implied: implied),
            name: child_sym.to_s.dasherize,
            selector: sel.css
          )
        in [obj] if obj.respond_to?(:stimulus_identifier)
          ident = obj.stimulus_identifier
          new(controller: implied, name: ident, selector: auto_selector(ident, component_id: component_id))
        in [Selector => sel]
          raise ::Vident::ParseError,
            "Outlet.parse: a Selector must be paired with a child controller name. " \
            "Use `(:name, Vident::Selector(#{sel.css.inspect}))` or " \
            "`(\"some/parent\", :name, Vident::Selector(...))` for the cross-controller form."
        in [_, String => sel]
          raise ::Vident::ParseError, raw_string_selector_message(sel)
        in [_, _, String => sel]
          raise ::Vident::ParseError, raw_string_selector_message(sel)
        else
          raise ::Vident::ParseError, "Outlet.parse: invalid arguments #{args.inspect}"
        end
      end

      def self.auto_selector(outlet_identifier, component_id:)
        prefix = component_id ? "##{css_escape_ident(component_id)} " : ""
        "#{prefix}[data-controller~=#{outlet_identifier}]"
      end

      # CSS-escapes anything outside the bare identifier alphabet
      # (`A-Za-z0-9_-`) using the `\HH ` hex form (with trailing space
      # delimiter). Bare `\<char>` works for many punctuation cases but
      # not for whitespace, parens, or non-ASCII — the hex form is
      # always valid per CSS Syntax §4.3.7.
      def self.css_escape_ident(id)
        id.to_s.gsub(/[^A-Za-z0-9_-]/) { |c| "\\#{c.ord.to_s(16)} " }
      end

      def self.raw_string_selector_message(value)
        "Outlet.parse: a bare String is a controller path, never a CSS selector. " \
          "Wrap verbatim selectors in `Vident::Selector(...)` (got #{value.inspect}). " \
          "For auto-selectors based on a child controller identifier, pass a Symbol or " \
          "an unwrapped String — Vident builds `[data-controller~=…]` for you."
      end

      def to_s = selector

      def data_attribute_key = :"#{controller.name}-#{name}-outlet"

      def to_data_pair = [data_attribute_key, selector]

      def to_h = {data_attribute_key => selector}
      alias_method :to_hash, :to_h
    end
  end
end
