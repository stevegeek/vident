# frozen_string_literal: true

require "json"
require "literal"
require_relative "naming"
require_relative "null"
require_relative "controller"

module Vident2
  module Stimulus
    # `data-<ctrl>-<name>-param` fragment — same shape as Value, distinct
    # semantics on the JS side (read via `event.params.<camel>`).
    class Param < ::Literal::Data
      prop :controller, Controller
      prop :name, String
      prop :serialized, String

      def self.parse(*args, implied:, component_id: nil)
        case args
        in [Symbol => name_sym, raw]
          new(
            controller: implied,
            name: name_sym.to_s.dasherize,
            serialized: serialize(raw)
          )
        in [String => ctrl_path, Symbol => name_sym, raw]
          new(
            controller: Controller.parse(ctrl_path, implied: implied),
            name: name_sym.to_s.dasherize,
            serialized: serialize(raw)
          )
        else
          raise ::Vident2::ParseError, "Param.parse: invalid arguments #{args.inspect}"
        end
      end

      def self.serialize(raw)
        raise ::Vident2::ParseError, "Param.serialize: nil is not serializable — filter nil upstream" if raw.nil?
        case raw
        when Array, Hash then raw.to_json
        else raw.to_s
        end
      end

      def to_s = serialized

      def data_attribute_key = :"#{controller.name}-#{name}-param"

      def to_data_pair = [data_attribute_key, serialized]

      def to_h = {data_attribute_key => serialized}
      alias_method :to_hash, :to_h

      def self.to_data_hash(params)
        params.each_with_object({}) do |p, acc|
          key, str = p.to_data_pair
          acc[key] = str
        end
      end
    end
  end
end
