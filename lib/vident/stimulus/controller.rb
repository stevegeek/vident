# frozen_string_literal: true

require "literal"
require_relative "naming"
require_relative "base"

module Vident
  module Stimulus
    # `data-controller` fragment.
    class Controller < Base
      prop :path, String
      prop :name, String
      prop :alias_name, _Nilable(Symbol), default: nil

      def self.parse(*args, implied:, as: nil, component_id: nil)
        case args.size
        when 0
          new(path: implied.path, name: implied.name, alias_name: as)
        when 1
          raw = args[0]
          if raw.respond_to?(:stimulus_identifier)
            name = raw.stimulus_identifier
            path = raw.respond_to?(:stimulus_identifier_path) ? raw.stimulus_identifier_path : name
            new(path: path, name: name, alias_name: as)
          else
            path = raw.to_s
            new(path: path, name: Naming.stimulize_path(path), alias_name: as)
          end
        else
          raise ::Vident::ParseError, "Controller.parse: expected 0 or 1 positional args, got #{args.size}"
        end
      end

      # Whether `value` is accepted in a cross-controller path slot: a path
      # String, or a Vident component (class or instance) that names itself.
      def self.path_arg?(value)
        value.is_a?(String) || value.respond_to?(:stimulus_identifier)
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
