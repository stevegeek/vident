# frozen_string_literal: true

require "json"
require "literal"
require_relative "naming"
require_relative "null"
require_relative "controller"

module Vident
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
          raise ::Vident::ParseError, "Param.parse: invalid arguments #{args.inspect}"
        end
      end

      def self.serialize(raw)
        raise ::Vident::ParseError, "Param.serialize: nil is not serializable — filter nil upstream" if raw.nil?
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
        params.to_h(&:to_data_pair)
      end
    end
  end
end
