# frozen_string_literal: true

require "literal"
require_relative "naming"

module Vident
  module Stimulus
    # `data-controller` fragment.
    class Controller < ::Literal::Data
      prop :path, String
      prop :name, String
      prop :alias_name, _Nilable(Symbol), default: nil

      def self.parse(*args, implied:, as: nil, component_id: nil)
        case args.size
        when 0
          new(path: implied.path, name: implied.name, alias_name: as)
        when 1
          raw = args[0]
          path = raw.to_s
          new(path: path, name: Naming.stimulize_path(path), alias_name: as)
        else
          raise ::Vident::ParseError, "Controller.parse: expected 0 or 1 positional args, got #{args.size}"
        end
      end

      def identifier = name

      def to_s = name

      def to_data_pair = [:controller, name]

      def to_h = {controller: name}
      alias_method :to_hash, :to_h

      def self.to_data_hash(controllers)
        return {} if controllers.empty?
        joined = controllers.map(&:name).reject(&:empty?).join(" ")
        return {} if joined.empty?
        {controller: joined}
      end
    end
  end
end
