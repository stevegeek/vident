# frozen_string_literal: true

require_relative "../stimulus/controller"
require_relative "../stimulus/action"
require_relative "../stimulus/target"
require_relative "../stimulus/outlet"
require_relative "../stimulus/value"
require_relative "../stimulus/param"
require_relative "../stimulus/class_map"

module Vident2
  # @api private — consumed by the DSL, Resolver, Draft, Plan,
  # AttributeWriter, and Capabilities::StimulusMutation. Not a public
  # extension surface; extensions monkeypatch at their own risk.
  module Internals
    module Registry
      # Metadata per kind:
      # - `name`        : canonical key (Symbol)
      # - `plural_name` : the DSL plural form (e.g. `:classes` for ClassMap)
      # - `value_class` : the Literal::Data value class
      # - `keyed`       : true for keyed kinds (one hash entry per instance:
      #                   values, params, class_maps, outlets);
      #                   false for positional kinds (controllers, actions,
      #                   targets — aggregated into one or grouped keys).
      Kind = Data.define(:name, :plural_name, :value_class, :keyed)

      KINDS = [
        Kind.new(:controllers, :controllers, Vident2::Stimulus::Controller, false),
        Kind.new(:actions,     :actions,     Vident2::Stimulus::Action,     false),
        Kind.new(:targets,     :targets,     Vident2::Stimulus::Target,     false),
        Kind.new(:outlets,     :outlets,     Vident2::Stimulus::Outlet,     true),
        Kind.new(:values,      :values,      Vident2::Stimulus::Value,      true),
        Kind.new(:params,      :params,      Vident2::Stimulus::Param,      true),
        Kind.new(:class_maps,  :classes,     Vident2::Stimulus::ClassMap,   true)
        # class_maps is the internal name; the DSL form reads `classes`.
      ].freeze

      BY_NAME = KINDS.to_h { |k| [k.name, k] }.freeze

      def self.fetch(name) = BY_NAME.fetch(name)
      def self.each(&block) = KINDS.each(&block)
      def self.names = BY_NAME.keys
    end
  end
end
