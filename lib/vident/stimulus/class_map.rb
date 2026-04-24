# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "base"
require_relative "controller"

module Vident
  module Stimulus
    # `data-<ctrl>-<name>-class` fragment — a named CSS class set readable
    # on the JS side as `this.<name>Class`.
    class ClassMap < Base
      prop :controller, Controller
      prop :name, String
      prop :css, String

      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Symbol => name_sym, css_input]
          new(
            controller: implied,
            name: name_sym.to_s.dasherize,
            css: normalize_css(css_input)
          )
        in [String => ctrl_path, Symbol => name_sym, css_input]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            name: name_sym.to_s.dasherize,
            css: normalize_css(css_input)
          )
        else
          raise ::Vident::ParseError, "ClassMap.parse: invalid arguments #{args.inspect}"
        end
      end

      def self.normalize_css(input)
        case input
        when String
          input.split(/\s+/).reject(&:empty?).join(" ")
        when Array
          input.map(&:to_s).reject(&:empty?).join(" ")
        else
          raise ::Vident::ParseError, "ClassMap.parse: css must be a String or Array, got #{input.class}"
        end
      end

      def to_s = css

      def data_attribute_key = :"#{controller.name}-#{name}-class"

      def to_data_pair = [data_attribute_key, css]

      def to_h = {data_attribute_key => css}
      alias_method :to_hash, :to_h
    end
  end
end
