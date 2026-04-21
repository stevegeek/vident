# frozen_string_literal: true

require_relative "../stimulus/controller"
require_relative "../stimulus/action"
require_relative "../stimulus/target"
require_relative "../stimulus/outlet"
require_relative "../stimulus/value"
require_relative "../stimulus/param"
require_relative "../stimulus/class_map"

module Vident
  module Internals
    module Registry
      Kind = Data.define(:name, :plural_name, :singular_name, :value_class, :keyed) do
        alias_method :keyed?, :keyed
      end

      KINDS = [
        Kind.new(:controllers, :controllers, :controller, Vident::Stimulus::Controller, false),
        Kind.new(:actions, :actions, :action, Vident::Stimulus::Action, false),
        Kind.new(:targets, :targets, :target, Vident::Stimulus::Target, false),
        Kind.new(:outlets, :outlets, :outlet, Vident::Stimulus::Outlet, true),
        Kind.new(:values, :values, :value, Vident::Stimulus::Value, true),
        Kind.new(:params, :params, :param, Vident::Stimulus::Param, true),
        Kind.new(:class_maps, :classes, :class, Vident::Stimulus::ClassMap, true)
      ].freeze

      BY_NAME = KINDS.to_h { |k| [k.name, k] }.freeze

      def self.fetch(name) = BY_NAME.fetch(name)

      def self.each(&block) = KINDS.each(&block)

      def self.names = BY_NAME.keys
    end
  end
end
