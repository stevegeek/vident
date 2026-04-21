# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "controller"

module Vident2
  module Stimulus
    # `data-<ctrl>-<name>-class` fragment — a named CSS class set readable
    # on the JS side as `this.<name>Class`. Renamed from v1's
    # `StimulusClass` (which collided with Ruby's `Class` — uncomfortable
    # to type in user code).
    #
    # `css` holds the final serialised string form (space-joined); the
    # parser normalises String / Array-of-String / Array-of-anything inputs
    # down to one shape so the Draft/Plan doesn't have to care.
    class ClassMap < ::Literal::Data
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
          raise ::Vident2::ParseError, "ClassMap.parse: invalid arguments #{args.inspect}"
        end
      end

      def self.normalize_css(input)
        case input
        when String
          input.split(/\s+/).reject(&:empty?).join(" ")
        when Array
          input.map(&:to_s).reject(&:empty?).join(" ")
        else
          raise ::Vident2::ParseError, "ClassMap.parse: css must be a String or Array, got #{input.class}"
        end
      end

      def to_s = css

      def data_attribute_key = :"#{controller.name}-#{name}-class"

      def to_data_pair = [data_attribute_key, css]

      def to_h = {data_attribute_key => css}
      alias_method :to_hash, :to_h

      def self.to_data_hash(maps)
        maps.each_with_object({}) do |m, acc|
          key, str = m.to_data_pair
          acc[key] = str
        end
      end
    end
  end
end
