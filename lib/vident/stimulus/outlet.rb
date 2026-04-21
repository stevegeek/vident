# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "controller"

module Vident
  module Stimulus
    # `data-<ctrl>-<name>-outlet` fragment. `selector` is the CSS selector
    # the Stimulus runtime uses to resolve the outlet on the page.
    class Outlet < ::Literal::Data
      prop :controller, Controller
      prop :name, String
      prop :selector, String

      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Symbol => sym]
          name = sym.to_s.dasherize
          new(
            controller: implied,
            name: name,
            selector: auto_selector(name, component_id: component_id)
          )
        in [String => str]
          name = str.dasherize
          new(
            controller: implied,
            name: name,
            selector: auto_selector(name, component_id: component_id)
          )
        in [[identifier, selector]]
          new(
            controller: implied,
            name: identifier.to_s.dasherize,
            selector: selector
          )
        in [Symbol => sym, String => sel]
          new(
            controller: implied,
            name: sym.to_s.dasherize,
            selector: sel
          )
        in [String => id_or_name, String => sel]
          new(
            controller: implied,
            name: id_or_name.dasherize,
            selector: sel
          )
        in [String => ctrl_path, Symbol => sym, String => sel]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            name: sym.to_s.dasherize,
            selector: sel
          )
        in [obj] if obj.respond_to?(:stimulus_identifier)
          ident = obj.stimulus_identifier
          new(
            controller: implied,
            name: ident,
            selector: auto_selector(ident, component_id: component_id)
          )
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

      def to_s = selector

      def data_attribute_key = :"#{controller.name}-#{name}-outlet"

      def to_data_pair = [data_attribute_key, selector]

      def to_h = {data_attribute_key => selector}
      alias_method :to_hash, :to_h

      def self.to_data_hash(outlets)
        outlets.to_h(&:to_data_pair)
      end
    end
  end
end
