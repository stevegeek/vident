# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "controller"

module Vident2
  module Stimulus
    # `data-<ctrl>-target` fragment. One per target reference; the Array
    # aggregator groups by controller and space-joins same-key values.
    class Target < ::Literal::Data
      prop :controller, Controller
      prop :name, String

      # `.parse(*args, implied:)`:
      #   (Symbol)         -> target `:name` on implied controller
      #   (String)         -> target name as-is on implied (already js-cased)
      #   (String, Symbol) -> explicit (controller_path, target_name)
      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Symbol => sym]
          new(controller: implied, name: Naming.js_name(sym))
        in [String => str]
          new(controller: implied, name: str)
        in [String => ctrl_path, Symbol => sym]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            name: Naming.js_name(sym)
          )
        else
          raise ::Vident2::ParseError, "Target.parse: invalid arguments #{args.inspect}"
        end
      end

      def to_s = name

      def data_attribute_key = :"#{controller.name}-target"

      def to_data_pair = [data_attribute_key, name]

      # Splat target for inline `data: {**target.to_h}` usage.
      def to_h = {data_attribute_key => name}
      alias_method :to_hash, :to_h

      # Same-key concat with space. Example:
      #   Target(row)                       -> "foo-target" => "row"
      #   Target(row) + Target(cell)        -> "foo-target" => "row cell"
      #   Target(row) + Target(x, on: bar)  -> {"foo-target"=>"row", "bar-target"=>"x"}
      def self.to_data_hash(targets)
        targets.each_with_object({}) do |t, acc|
          key, value = t.to_data_pair
          acc[key] = acc.key?(key) ? "#{acc[key]} #{value}" : value
        end
      end
    end
  end
end
