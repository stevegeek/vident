# frozen_string_literal: true

require "json"
require "literal"
require_relative "naming"
require_relative "base"
require_relative "controller"
require_relative "null"

module Vident
  module Stimulus
    # `data-<ctrl>-<name>-value` fragment. Holds the serialised form
    # (always a String). Only `nil` is rejected — `false`, blank strings,
    # and empty collections emit their serialised form.
    class Value < Base
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
          raise ::Vident::ParseError, "Value.parse: invalid arguments #{args.inspect}"
        end
      end

      def self.serialize(raw)
        raise ::Vident::ParseError, "Value.serialize: nil is not serializable — filter nil upstream" if raw.nil?
        case raw
        when Array, Hash then raw.to_json
        else raw.to_s
        end
      end

      def to_s = serialized

      def data_attribute_key = :"#{controller.name}-#{name}-value"

      def to_data_pair = [data_attribute_key, serialized]

      def to_h = {data_attribute_key => serialized}
      alias_method :to_hash, :to_h
    end
  end
end
