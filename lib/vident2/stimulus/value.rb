# frozen_string_literal: true

require "json"
require "literal"
require_relative "naming"
require_relative "controller"
require_relative "null"

module Vident2
  module Stimulus
    # `data-<ctrl>-<name>-value` fragment. Holds the *serialised* form
    # (always a String post-parse); Array/Hash inputs go through `to_json`,
    # other non-nil inputs through `to_s`. The `Null` sentinel's `to_s`
    # produces `"null"` naturally. Only `nil` drops at the caller —
    # `false`, blank strings, and empty collections emit their serialised
    # form.
    class Value < ::Literal::Data
      prop :controller, Controller
      prop :name, String
      prop :serialized, String

      # `.parse(*args, implied:)` grammar:
      #   (Symbol, raw)           -> implied controller, value named `Symbol`
      #   (String, Symbol, raw)   -> explicit (controller_path, name, raw)
      #
      # The caller (Resolver / mutator) is responsible for filtering out
      # `nil` before reaching here — see `serialize` for the check.
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
          raise ::Vident2::ParseError, "Value.parse: invalid arguments #{args.inspect}"
        end
      end

      # Raw -> String. `Null` sentinel serialises to `"null"` via its
      # own `to_s`. `nil` should have been filtered upstream; raising
      # here catches misrouted callers early.
      def self.serialize(raw)
        raise ::Vident2::ParseError, "Value.serialize: nil is not serializable — filter nil upstream" if raw.nil?
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

      # One entry per Value instance. Later-instance same-key wins on
      # collision (Hash#merge semantics).
      def self.to_data_hash(values)
        values.each_with_object({}) do |v, acc|
          key, str = v.to_data_pair
          acc[key] = str
        end
      end
    end
  end
end
