# frozen_string_literal: true

require "literal"
require_relative "naming"

module Vident2
  module Stimulus
    # `data-controller` fragment. Fields:
    # - `path`    : raw underscored path (e.g. `"admin/user_card_component"`)
    # - `name`    : dasherized/joined form (e.g. `"admin--user-card-component"`)
    # - `alias_name`: optional Symbol the DSL uses to refer back to this
    #   controller from other entries (`action(:save, on: :admin)`).
    class Controller < ::Literal::Data
      prop :path, String
      prop :name, String
      prop :alias_name, _Nilable(Symbol), default: nil

      # `.parse(path = nil, as: nil, implied:)`
      #
      # No positional arg -> clone the implied controller (for unambiguous
      # "refer to my own controller" use).
      #
      # One positional arg (String | Symbol) -> explicit controller path.
      # `implied:` is unused in that branch but is accepted for uniformity
      # with the other kinds' `.parse` signatures.
      def self.parse(*args, as: nil, implied:, component_id: nil)
        case args.size
        when 0
          new(path: implied.path, name: implied.name, alias_name: as)
        when 1
          raw = args[0]
          path = raw.to_s
          new(path: path, name: Naming.stimulize_path(path), alias_name: as)
        else
          raise ::Vident2::ParseError, "Controller.parse: expected 0 or 1 positional args, got #{args.size}"
        end
      end

      def identifier = name

      def to_s = name

      def to_data_pair = [:controller, name]

      def to_h = {controller: name}
      # Ruby's `{**x}` splat calls #to_hash; alias so users can splat the
      # data-attr pair directly into a tag's `data:` option.
      alias_method :to_hash, :to_h

      # Space-joined. Order preserved, duplicates kept (caller dedups).
      def self.to_data_hash(controllers)
        return {} if controllers.empty?
        joined = controllers.map(&:name).reject(&:empty?).join(" ")
        return {} if joined.empty?
        {controller: joined}
      end
    end
  end
end
