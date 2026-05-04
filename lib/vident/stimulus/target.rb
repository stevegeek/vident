# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "base"
require_relative "controller"

module Vident
  module Stimulus
    # `data-<ctrl>-target` fragment.
    class Target < Base
      prop :controller, Controller
      prop :name, String

      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Symbol => sym]
          new(controller: implied, name: Naming.js_name(sym))
        in [String => ctrl_path, Symbol => sym]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            name: Naming.js_name(sym)
          )
        in [String => s]
          raise ::Vident::ParseError,
            "Target.parse: a bare String is a controller path; target names must be Symbols " \
            "(got #{s.inspect}). Use `target :name` for a local target, or " \
            "`target \"path/to/ctrl\", :name` for cross-controller."
        else
          raise ::Vident::ParseError, "Target.parse: invalid arguments #{args.inspect}"
        end
      end

      def to_s = name

      def data_attribute_key = :"#{controller.name}-target"

      def to_data_pair = [data_attribute_key, name]

      def to_h = {data_attribute_key => name}
      alias_method :to_hash, :to_h

      def self.to_data_hash(targets)
        targets.each_with_object({}) do |t, acc|
          key, value = t.to_data_pair
          acc[key] = acc.key?(key) ? "#{acc[key]} #{value}" : value
        end
      end
    end
  end
end
