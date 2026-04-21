# frozen_string_literal: true

require "test_helper"
require "vident"

module Vident
  class RegistryTest < Minitest::Test
    # ---- Kind#keyed? predicate ------------------------------------------

    def test_keyed_predicate_matches_keyed_field_for_all_kinds
      Vident::Internals::Registry::KINDS.each do |kind|
        assert_equal kind.keyed, kind.keyed?,
          "#{kind.name}: keyed? should equal keyed field"
      end
    end

    def test_values_kind_is_keyed
      kind = Vident::Internals::Registry.fetch(:values)
      assert kind.keyed?, ":values should be keyed"
    end

    def test_params_kind_is_keyed
      kind = Vident::Internals::Registry.fetch(:params)
      assert kind.keyed?, ":params should be keyed"
    end

    def test_class_maps_kind_is_keyed
      kind = Vident::Internals::Registry.fetch(:class_maps)
      assert kind.keyed?, ":class_maps should be keyed"
    end

    def test_outlets_kind_is_keyed
      kind = Vident::Internals::Registry.fetch(:outlets)
      assert kind.keyed?, ":outlets should be keyed"
    end

    def test_actions_kind_is_not_keyed
      kind = Vident::Internals::Registry.fetch(:actions)
      refute kind.keyed?, ":actions should not be keyed"
    end

    def test_controllers_kind_is_not_keyed
      kind = Vident::Internals::Registry.fetch(:controllers)
      refute kind.keyed?, ":controllers should not be keyed"
    end

    def test_targets_kind_is_not_keyed
      kind = Vident::Internals::Registry.fetch(:targets)
      refute kind.keyed?, ":targets should not be keyed"
    end

    def test_keyed_predicate_and_keyed_field_return_same_value
      Vident::Internals::Registry::KINDS.each do |kind|
        assert_equal kind.keyed, kind.keyed?,
          "#{kind.name}: keyed? alias must match keyed field"
      end
    end

    def test_exactly_four_kinds_are_keyed
      keyed_names = Vident::Internals::Registry::KINDS.select(&:keyed?).map(&:name)
      assert_equal %i[outlets values params class_maps], keyed_names
    end

    def test_exactly_three_kinds_are_not_keyed
      positional_names = Vident::Internals::Registry::KINDS.reject(&:keyed?).map(&:name)
      assert_equal %i[controllers actions targets], positional_names
    end
  end
end
